module main;

import kratos.ecs;

//version(unittest):

void main()
{

}

class Transform : Component
{
	mixin SerializationRegistration;
}

class Camera : Component
{
	mixin SerializationRegistration;

	private @dependency:
	Transform transform;
	RendererSpacePartitioning partitioning;
}

class CameraMovement : Component
{
	mixin SerializationRegistration;

	private @dependency:
	Transform transform;
	Camera camera;
}

class MeshRenderer : Component
{
	mixin SerializationRegistration;

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
	mixin SerializationRegistration;
}

class RendererSpacePartitioning : SceneComponent
{
	mixin SerializationRegistration;
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

	import std.stdio;
	writeln(scene.serializeToPrettyJson());

	writeln(scene.entities.front.components.all);
}