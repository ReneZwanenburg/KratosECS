module kratos.ecs.component;

import std.container : Array;
import std.typecons : Flag;
import std.traits : ReturnType;

import vibe.data.json;

import kratos.util;

alias AllowDerived = Flag!"AllowDerived";
private alias DefaultAllowDerived = AllowDerived.yes;


struct Dependency
{
	AllowDerived allowDerived = DefaultAllowDerived;
}

@property Dependency dependency(AllowDerived allowDerived = DefaultAllowDerived)
{
	return Dependency(allowDerived);
}

//TODO: Make generic Ref struct
struct ComponentContainerRef(ComponentBaseType)
{
	private ComponentContainer!ComponentBaseType* _container;

	@disable this();

	private this(ComponentContainer!ComponentBaseType* container)
	{
		this._container = container;
	}

	alias release this;

	public @property ref release()
	{
		return *_container;
	}
}

struct ComponentContainer(ComponentBaseType)
{
	alias OwnerType = typeof(ComponentBaseType.init.owner);

	private Array!ComponentBaseType _components;
	private OwnerType _owner;

	@disable this();

	this(OwnerType owner)
	{
		assert(owner !is null);
		this._owner = owner;
	}

	package auto getRef()
	{
		return ComponentContainerRef!ComponentBaseType(&this);
	}

	T add(T)() if(is(T : ComponentBaseType))
	{
		ComponentBaseType.constructingOwner = _owner;
		auto component = new T();
		ComponentBaseType.constructingOwner = null;

		// Add the component to the array before initializing, so cyclic dependencies can be resolved
		_components.insertBack(component);
		ComponentInteraction!T.initialize(component);

		return component;
	}

	T first(T, AllowDerived derived = DefaultAllowDerived)() if(is(T : ComponentBaseType))
	{
		auto range = all!(T, derived);
		return range.empty ? null : range.front;
	}

	auto all(T, AllowDerived derived = DefaultAllowDerived)()  if(is(T : ComponentBaseType))
	{
		import std.traits : isFinalClass;
		import std.algorithm.iteration : map, filter;

		static if(derived && !isFinalClass!T)
		{
			return
				_components[]
				.map!(a => cast(T)a)
				.filter!(a => a !is null);
		}
		else
		{
			return
				_components[]
				.filter!(a => a.classinfo is T.classinfo)
				.map!(a => cast(T)(cast(void*)a));
		}
	}

	T firstOrAdd(T, AllowDerived derived = DefaultAllowDerived)() if(is(T : ComponentBaseType))
	{
		auto component = first!(T, derived);
		return component is null ? add!T : component;
	}


	static ComponentContainer fromRepresentation(Json containerRepresentation)
	{
		auto container = ComponentContainer(OwnerType.currentlyDeserializing);

		ComponentBaseType.constructingOwner = container._owner;

		foreach(componentRepresentation; containerRepresentation[])
		{
			auto fullTypeName = componentRepresentation["type"].get!string;
			auto deserializer = deserializers[fullTypeName];

			deserializer(componentRepresentation); // Added to _components in deserializer
		}

		ComponentBaseType.constructingOwner = null;

		return container;
	}

	//TODO: Serialization
}


template ComponentInteraction(ComponentType)
{

	private void initialize(ComponentType component)
	{
		import std.traits;
		import vibe.internal.meta.uda : findFirstUDA;

		foreach(i, T; typeof(ComponentType.tupleof))
		{
			enum uda = findFirstUDA!(Dependency, ComponentType.tupleof[i]);
			static if(uda.found)
			{
				component.tupleof[i] = ComponentType.resolveDependency!(T, uda.value)(component.owner);
			}
		}
	}

}

private template ComponentSerialization(ComponentType)
{
private:
	enum fullTypeName = typeid(ComponentType).name;
	pragma(msg, "Generating Serialization routines for " ~ fullTypeName);

	Json serialize(ComponentType component)
	{
		assert(typeid(ComponentType) == typeid(component), "Component ended up in the wrong serializer");

		auto representation = Json.emptyObject;
		representation["type"] = fullTypeName;
		representation["representation"] = serializeToJson(component);
		return representation;
	}

	void deserialize(Json representation)
	{
		assert(fullTypeName == representation["type"].get!string, "Component representation ended up in the wrong deserializer");

		auto component = deserializeJson!ComponentType(representation["representation"]);
		component.owner.components._components.insertBack(component);
		ComponentInteraction!ComponentType.initialize(component);
	}

	static this()
	{
		deserializers[fullTypeName] = &deserialize;
		serializers[fullTypeName] = cast(ComponentSerializer)&serialize;
	}
}

private
{
	alias ComponentDeserializer = void function(Json);
	alias ComponentSerializer = Json function(Object);

	ComponentDeserializer[string] deserializers;
	ComponentSerializer[string] serializers;
}