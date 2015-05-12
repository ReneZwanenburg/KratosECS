module main;

import kratos.ecs;

//version(unittest):

void main()
{

}

class Transform : Component
{

}

class Camera : Component
{
	private @dependency:
	Transform transform;
	RendererSpacePartitioning partitioning;
}

class CameraMovement : Component
{
	private @dependency:
	Transform transform;
	Camera camera;
}

class MeshRenderer : Component
{
	private @dependency:
	Transform transform;
	RendererSpacePartitioning partitioning;
}

class RigidBody : Component
{
	mixin SerializationRegistration;

	private @dependency:
	Transform transform;
	PhysicsSimulation physics;
}

class PhysicsSimulation : SceneComponent
{

}

class RendererSpacePartitioning : SceneComponent
{

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

unittest
{
	import vibe.data.json;

	string data = 
		`
		{
			"components":
			[

			],
			"entities":
			[
				{
					"components":
					[
						{
							"type": "main.RigidBody"
						}
					]
				}
			]
		}
		`;

	auto json = parseJsonString(data);
	auto scene = deserializeJson!Scene(json);
}