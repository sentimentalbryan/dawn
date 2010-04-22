package uk.co.ziazoo.injector.impl
{
  import flash.utils.Dictionary;
  import flash.utils.getDefinitionByName;

  import uk.co.ziazoo.injector.IMapper;
  import uk.co.ziazoo.injector.IMapping;
  import uk.co.ziazoo.injector.IMappingBuilder;

  internal class Mapper implements IMapper
  {
    /**
     * array of builders with mappings that have not yet
     * been added to the typesMap
     */
    private var builders:Array;

    /**
     * map of mappings [Class][String]
     */
    private var mappings:Dictionary;
    
    private var eagers:Array;
    private var reflector:Reflector;

    public function Mapper(reflector:Reflector)
    {
      mappings = new Dictionary();
      builders = [];
      this.reflector = reflector;
    }

    /**
     * @inheritDoc
     */
    public function map(type:Class):IMappingBuilder
    {
      var builder:IMappingBuilder = new MappingBuilder(type, reflector, this);
      builders.push(builder);
      return builder;
    }

    /**
     * @private
     *
     * adds any mappings in the builders array
     */
    internal function processBuilders():void
    {
      for each(var builder:IMappingBuilder in builders)
      {
        for each(var mapping:IMapping in builder.getMappings())
        {
          add(mapping);
        }
      }
      builders = [];
    }

    /**
     * @inheritDoc
     */
    public function getMapping(type:Class, name:String = ""):IMapping
    {
      processBuilders();

      if(mappings[type])
      {
        var key:String = name == "" || !name ? "no_name" : name;
        return mappings[type][key] as IMapping;
      }
      return null;
    }

    /**
     * @inheritDoc
     */
    public function getMappingForQName(
      qName:String, name:String = ""):IMapping
    {
      var type:Class = getDefinitionByName(qName) as Class;
      return getMapping(type, name);
    }

    /**
     * @inheritDoc
     */
    public function addToEagerQueue(mapping:IMapping):void
    {
      if (!eagers)
      {
        eagers = [];
      }
      eagers.push(mapping);
    }

    /**
     * @inheritDoc
     */
    public function getEagerQueue():Array
    {
      var queue:Array = [];
      for each(var mapping:IMapping in eagers)
      {
        queue.push(mapping);
      }
      eagers = [];
      return queue;
    }

    /**
     * @inheritDoc
     */
    public function hasMapping(type:Class, name:String = ""):Boolean
    {
      return getMapping(type, name) != null;
    }

    /**
     * @inheritDoc
     */
    public function add(mapping:IMapping):void
    {
        if(!mappings[mapping.type])
        {
          mappings[mapping.type] = new Dictionary();
        }
        var key:String = mapping.name == "" || !mapping.name ? "no_name" : mapping.name;
        mappings[mapping.type][key] = mapping;
    }

    /**
     * @inheritDoc
     */
    public function remove(mapping:IMapping):void
    {
      removeFor(mapping.type, mapping.name);
    }

    /**
     * @inheritDoc
     */
    public function removeFor(type:Class, name:String = ""):void
    {
      if(mappings[type])
      {
        var byName:Dictionary = mappings[type] as Dictionary;
        if(byName[name])
        {
          delete byName[name];
        }
      }
    }

    /**
     * @inheritDoc
     */
    public function justInTimeMap(type:Class, name:String = ""):IMappingBuilder
    {
      var builder:IMappingBuilder = map(type).named(name);
      builder.baseMapping.isJustInTime = true;
      builders.push(builder);
      return builder;
    }

    /**
     * @inheritDoc
     */
    public function justInTimeMapByQName(qName:String, name:String = ""):IMappingBuilder
    {
      return justInTimeMap(getDefinitionByName(qName) as Class, name);
    }

    /**
     * @inheritDoc
     */
    public function newBuilder(type:Class):IMappingBuilder
    {
      return new MappingBuilder(type, reflector, this);
    }
  }
}