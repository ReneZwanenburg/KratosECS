module kratos.ecs.scene;

import std.container.array;

import kratos.ecs.component;
import kratos.ecs.entity;

import vibe.data.json;

public abstract class SceneComponent
{
	package static Scene constructingOwner;

	private Scene _owner;

	protected this()
	{
		assert(constructingOwner !is null);
		this._owner = constructingOwner;
	}

	final @property
	{
		inout(Scene) owner() inout
		{
			return _owner;
		}
	}


	package static auto resolveDependency(FieldType, Dependency dependency)(Scene owner)
	{
		static if(is(FieldType : SceneComponent))
		{
			enum allowDerived = dependency.allowDerived;
			return owner.components.firstOrAdd!(FieldType, allowDerived);
		}
		else static assert(false, "Invalid Dependency type: " ~ T.stringof);
	}
}

public final class Scene
{
	alias Components = ComponentContainer!SceneComponent;

	private Components _components;
	private Array!Entity _entities;

	this()
	{
		_components = Components(this);
	}

	Entity createEntity()
	{
		auto entity = new Entity(this);
		_entities.insertBack(entity);
		return entity;
	}

	@property
	{
		auto entities()
		{
			return _entities[];
		}

		auto components()
		{
			return _components.getRef();
		}
	}

	public static Scene fromRepresentation(Json representation)
	{
		auto scene = new Scene();
		currentlyDeserializing = scene;
		scope(exit) currentlyDeserializing = null;

		auto componentsRepresentation = representation["components"];
		if(componentsRepresentation.type != Json.Type.undefined)
		{
			scene._components = deserializeJson!Components(componentsRepresentation);
		}

		auto entitiesRepresentation = representation["entities"];
		if(entitiesRepresentation.type != Json.Type.undefined)
		{
			assert(entitiesRepresentation.type == Json.Type.array);

			foreach(entityRepresentation; representation["entities"][])
			{
				Entity.deserialize(scene, entityRepresentation);
			}
		}

		return scene;
	}
	
	Json toRepresentation()
	{
		//TODO: Serialization
		return Json.emptyObject;
	}

	package static Scene currentlyDeserializing;
}
