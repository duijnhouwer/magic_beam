
% Script to show 4 Purkinje reflections

%* Set all magic_beam settings to their defaults
mb.settings('factory_reset');

%* Create a Le Grand model eyeball
eye = mb.body.eye.LeGrand;
eye.xpos = 0;
eye.ypos = 0;
eye.orientation=5;

%* Create a lightsource
light = mb.Light;
light.xpos = 60;
light.ypos = 0;
light.ray_angles = -180;

%* Add the body and the light to a scene
scene = mb.Scene;
scene.add_body(eye);
scene.add_light(light);

%* Let there be light
scene.shine

%* show the figure
scene.show('title','Purkinje reflections')