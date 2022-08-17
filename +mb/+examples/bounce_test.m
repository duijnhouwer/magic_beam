

clear all
clf

mb.settings('factory_reset');
mb.settings('reflex',true,'refract',true,'verbose',1,'infinite_ray_display_length',10);

%% Create a glass blockrays
block = mb.body.Rect;
block.n1n2=[1.333 1];
block.media=["water" "air"];
block.orientation=40;


%% Create a lightsource
light = mb.Light;

light.xpos = 10;
light.ypos = 0;
light.ray_angles = 180;
light.rays(1).medium="air";
light.linewidth=2;

%% Add the body and the light to a scene
scene = mb.Scene('max_generations_per_ray',5);
scene.add_body(block);
scene.add_light(light);

%scene.show
%drawnow
%
%% Let there be light
scene.shine

%% show the figure
scene.show('equal',true)