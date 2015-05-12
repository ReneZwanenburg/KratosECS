module kratos.ecs.scene;

import std.container.array;

import kratos.ecs.component;
import kratos.ecs.entity;

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

	//TODO: Serialization / deserialization

	package static Scene currentlyDeserializing;
}

unittest
{
	auto scene = new Scene();
	auto entity = scene.createEntity();

	static class SomeSceneComponent : SceneComponent
	{
		@dependency SomeSceneComponent self;
	}

	static class SomeEntityComponent : Component
	{

	}

	static class SomeOtherEntityComponent : Component
	{
		@dependency SomeSceneComponent mySceneDependency;
		@dependency SomeEntityComponent myEntityDependency;
	}

	auto sceneComponent = scene.components.add!SomeSceneComponent;
	auto entityComponent = entity.components.add!SomeOtherEntityComponent;

	assert(sceneComponent.self is sceneComponent);
	assert(entityComponent.myEntityDependency !is null);
	assert(entityComponent.mySceneDependency is sceneComponent);
}