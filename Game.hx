class Game extends hxd.App
{
    static function main()
    {
        // Инициализация системы ресурсов Heaps
        #if hl
        // В HashLink будем работать с файлами локально
        hxd.Res.initLocal();
        #else
        // В JavaScript будем использовать встраиваемые в js-файл данные
        hxd.Res.initEmbed();
        #end
        new Game();
    }

    override function init() 
    {
        // Загрузка данных для базы из файла data.cdb
        Data.load(hxd.Res.data.entry.getText());

        // Получаем данные о всех игровых уровнях, которые хранятся на листе levelData
        var allLevels = Data.levelData;
        // Загружаем данные о первом (и единственном) уровне, который хранится в базе
        var level = new h2d.CdbLevel(allLevels, 0, s2d);

        // Доступ к каждому из тайловых слоев уровня
        for (layer in level.layers)
        {
            trace(layer.name);
        }

        // Также можно запросить тайловый слой по его имени
        var objectsLayer = level.getLevelLayer("objects");

        // Посмотрим размеры уровня в тайлах:
        trace(level.width);
        trace(level.height);

        // Определяем размер тайла на уровне:
        var tileSize:Int = level.layers[0].tileset.size;

        // В этот массив будем добавлять наших npc
        var npcs:Array<h2d.Bitmap> = [];

        // Итерируем по всем npc на первом уровне:
        for (npc in allLevels.all[0].npcs)
        {
            // У npc может быть задан item, который является ссылкой 
            // на тип item с полями id и tile
            if (npc.item != null)
            {
                trace("NPC Item: " + npc.item.id);
            }

            // У npc есть поле kind, являющееся ссылкой 
            // на тип (лист в таблице) npc с полями: id, name, image и т.д.
            // Нас интересует поле image с типом Tile
            // У таких полей есть свойства size, file, x, y, ?width, ?height
            var npcImage = npc.kind.image;

            // Определяем размер тайла в изображении
            var npcTileSize = npc.kind.image.size;

            // Свойства тайла width и height являются необязательными:
            var npcWidth = (npcImage.width == null) ? 1 : npcImage.width;
            var npcHeight = (npcImage.height == null) ? 1 : npcImage.height;

            // Загружаем файл изображения, из которого берется тайл для npc
            var image = hxd.Res.load(npcImage.file).toImage();
            // И создаем из изображения тайл с необходимыми параметрами
            var npcTileX = npcImage.x * npcTileSize;
            var npcTileY = npcImage.y * npcTileSize;
            var npcTileWidth = npcWidth * npcTileSize;
            var npcTileHeight = npcHeight * npcTileSize;
            var npcTile = image.toTile().sub(npcTileX, npcTileY, npcTileWidth, npcTileHeight);

            // Используем этот тайл для создания объекта на сцене
            var b = new h2d.Bitmap(npcTile, s2d);
            // Позиционируем объект на сцене в соответствии данными из редактора
            b.x = tileSize * npc.x - (npcWidth - 1) * npcTileSize;
            b.y = tileSize * npc.y - (npcHeight - 1) * npcTileSize;

            npcs.push(b);
        }

        // Создаем тайл и объект TileGroup, с помощью которых будем отображать слой
        var colorTile = h2d.Tile.fromColor(0x0000ff, 16, 16, 0.5);
        var triggerGroup = new h2d.TileGroup(colorTile, s2d);
        
        // Получаем данные слоя triggers у уровня с идентификатором FirstVillage
        var triggers = allLevels.get(FirstVillage).triggers;

        // Итерируем по всем заданным областям
        for (trigger in triggers)
        {
            // В зависимости от типа триггера можем делать все что угодно
            switch (trigger.action)
            {
                case ScrollStop:
                    trace("Stop scrolling the map");
                case Goto(level, anchor):
                    trace('Travel to $level-$anchor');
                case Anchor(label):
                    trace('Anchor zone $label');
                default:

            }

            for (x in 0...trigger.width)
            {
                for (y in 0...trigger.height)
                {
                    triggerGroup.add((trigger.x + x) * tileSize, (trigger.y + y) * tileSize, colorTile);
                }
            }
        }

        // Берем строку с идентификатором Full на странице collide
        // и читаем в этой строке свойство icon, 
        // используя которое загружаем изображение
        var collideImage = hxd.Res.load(Data.collide.get(Full).icon.file).toImage();
        // Создаем группу для отображения свойства collide
        var collideGroup = new h2d.TileGroup(collideImage.toTile(), s2d);
        
        // Читаем свойство collide у всех слоев уровня:
        var tileProps = level.buildStringProperty("collide");
        // buildStringProperty - возвращает массив строк,
        // длина этого массива равна количеству тайлов на уровне.
        // Также доступен метод buildIntProperty, возвращающий массив Int'ов.
        // Кроме того, свойства можно считывать не только у всего уровня, 
        // но и у каждого из слоев по отдельности - для этого у слоев есть
        // одноименные методы.

        // Создаем тайлы для отображения свойств на экране
        for (ty in 0...level.height)
        {
            for (tx in 0...level.width)
            {
                var index = tx + ty * level.width;

                // Свойство тайла в позиции (tx, ty)
                var tileProp = tileProps[index];

                if (tileProp != null)
                {
                    // Считываем данные со страницы collide для соответствующего типа тайла
                    var collideData = Data.collide.get(cast tileProp);
                    var collideIcon = collideData.icon;
                    var collideSize = collideIcon.size;

                    // создаем тайл
                    var collideTile = collideImage.toTile().sub(collideIcon.x * collideSize, collideIcon.y * collideSize, collideSize, collideSize);
                    // и добавляем его на экран
                    collideGroup.addAlpha(tileSize * tx, tileSize * ty, 0.4, collideTile);
                }
            }
        }

        trace(tileProps.length);

        // Словарь с группами тайлов
        var tileGroups = objectsLayer.tileset.groups;

        // Просто считаем количество тайлов в каждой группе
        for (key in tileGroups.keys())
        {
            var group = tileGroups.get(key);
            trace(key + ": " + group.tiles.length);
        }
        
        // Покажем на экране анимацию из тайлов группы anim_fall
        var animFall = tileGroups.get("anim_fall");
        var anim = new h2d.Anim(animFall.tiles, 10, s2d);
        
        /*for (coll in Data.collide.all)
        {
            trace(coll.id);
        }*/

        var images = loadImagesFromImg("data.img");

        for (image in Data.images.all)
        {
            var name = image.name;

            // В примере на листе images есть столбец stats,
            // имеющий тип Flags.
            // здесь я хотел бы показать как работать с таким типом в Haxe.
            // У объектов такого типа есть метод has(), позволяющий
            // определить выставлен ли определенный флаг 
            var canClimb = image.stats.has(canClimb);
            var canEatBamboo = image.stats.has(canEatBamboo);
            var canRun = image.stats.has(canRun);

            // А также есть метод-итератор, позволяющий прочитать значения флагов
            for (stat in image.stats.iterator())
            {
                trace("stat: " + stat);
            }
            
            trace(name);
            trace("canClimb: " + canClimb);
            trace("canEatBamboo: " + canEatBamboo);
            trace("canRun: " + canRun);

            // Используем загруженный Image для создания экранного объекта
            var tile = images.get(image.image).toTile();
            var b = new h2d.Bitmap(tile, s2d);
            b.x = image.x;
            b.y = image.y;
        }

        // Проходим по всем npc
        for (npc in Data.npc.all)
        {
            trace(npc.type);
            // enum, сгенерированный библиотекой castle
            trace(Data.Npc_type.Normal);

            // загружаем текст
            trace(hxd.Res.load(npc.datafile).toText());
        }

        for (item in Data.item.all)
        {
            trace("item.id: " + item.id);
        }
    }

    /**
     * Загрузка изображений из img-файла 
     **/
    function loadImagesFromImg(fileName:String):Map<String, hxd.res.Image>
    {
        var images = new Map<String, hxd.res.Image>();

        // Загружаем img-файл и парсим его
        var jsonData = haxe.Json.parse(hxd.Res.load(fileName).toText());
        var fields = Reflect.fields(jsonData);

        // Проходим по всем полям полученного объекта
        for (field in fields)
        {
            var imgString:String = Reflect.field(jsonData, field);
            // удаляем префикс, который CastleDB добавляет перед данными изображения
            imgString = imgString.substr(imgString.indexOf("base64,") + "base64,".length);

            // Декодируем данные изображения и загружаем их в Image (контейнер данных изображения)
            var bytes = haxe.crypto.Base64.decode(imgString);
            var bytesFile = new hxd.fs.BytesFileSystem.BytesFileEntry(field, bytes);
            var image = new hxd.res.Image(bytesFile);

            images.set(field, image);
        }

        return images;
    }
}