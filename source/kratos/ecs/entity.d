module kratos.ecs.entity;

import kratos.ecs.component;
import kratos.ecs.scene;

import vibe.data.json;

public abstract class Component
{
	package static Entity constructingOwner;

	private Entity _owner;

	protected this()
	{
		assert(constructingOwner !is null);
		this._owner = constructingOwner;
	}

	final @property
	{
		inout(Entity) owner() inout
		{
			return _owner;
		}

		inout(Scene) scene() inout
		{
			return owner.scene;
		}
	}


	package static auto resolveDependency(FieldType, Dependency dependency)(Entity owner)
	{
		enum allowDerived = dependency.allowDerived;

		static if(is(FieldType : Component))
		{
			return owner.components.firstOrAdd!(FieldType, allowDerived);
		}
		else static if(is(FieldType : SceneComponent))
		{
			return owner.scene.components.firstOrAdd!(FieldType, allowDerived);
		}
		else static assert(false, "Invalid Dependency type: " ~ T.stringof);
	}
}

public final class Entity
{
	alias Components = ComponentContainer!Component;

	private Components _components;
	private Scene _scene;

	package this(Scene scene)
	{
		assert(scene !is null);
		this._scene = scene;
		_components = Components(this);
	}

	//Internal use only, used for deserialization
	this()
	{
		this(Scene.currentlyDeserializing);
	}

	@property
	{
		inout(Scene) scene() inout
		{
			return _scene;
		}

		auto components()
		{
			return _components.getRef();
		}
	}

	package static void deserialize(Scene owner, Json representation)
	{
		auto entity = owner.createEntity();

		auto componentsRepresentation = representation["components"];
		if(componentsRepresentation.type != Json.Type.undefined)
		{
			currentlyDeserializing = entity;
			entity._components = deserializeJson!Components(componentsRepresentation);
			currentlyDeserializing = null;
		}
	}

	//TODO: Serialization

	package static Entity currentlyDeserializing;
}
