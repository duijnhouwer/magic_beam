
function monocular_parallax

    % Demonstration of monocular parallax

    %* Set all magic_beam settings to their defaults
    mb.settings('factory_reset');
    mb.settings('reflex',false)
   
    gamma=0.1;

    orientations=[0 15];

    for i=1:numel(orientations)

        [scene,RGB,xx,yy]=render_two_light_scene(orientations(i));

        subplot(2,numel(orientations),i);
        image(xx,yy,RGB.^gamma);
        hold on
        scene.show('ray_visibility',0);
        axis manual
        set(gca,'XLim',[min(xx) max(xx)],'YLim',[min(yy) max(yy)]);

    end

end

function [scene,RGB,xx,yy]=render_two_light_scene(eye_orientation)

    %* Create a Le Grand model eyeball
    eye = mb.body.eye.Arizona;
    eye.xpos = 0;
    eye.ypos = 0;
    eye.orientation=eye_orientation;
    eye.color=[1 1 1 1];
    eye.linewidth=2;

    % 
    for i=1:2
        if i==1
            distance=300;
        else
            distance=6000;
        end
        %* Create the near light
        light = mb.Light;
        light.xpos = distance;
        light.ypos = 0;
        light.aim_rays_at_line_segment(100,[0 10],[0 -10]);
        %* Add the body and the light to a scene
        scene = mb.Scene;
        scene.add_body(eye);
        scene.add_light(light);
        %* Let there be light
        scene.shine
        % Rasterize the rays
        [I(:,:,i),xx,yy] = mb.library.Plot.rasterize_rays('rays',scene.rays,'xlim',[-30 50],'ylim',[-18 18],'pxsize',1); %#ok<AGROW> 
    end

    %% Create an RGB image where light1 is red and light2 is blue
    I=mb.library.Math.clamp(I,[0 1]);
    RGB=zeros(size(I,1),size(I,2),3);
    RGB(:,:,1)=I(:,:,1);
    RGB(:,:,3)=I(:,:,2);

end

