function navarro_accommodation_exploration
    

    mb.settings('reflex',0);

    %% Change in shape
    mb.library.Plot.find_fig('Eyeball 0 dpt vs5 dpt');
    %e0=mb.body.eye.Navarro('accommodation',0,'color',[0 0 0 1]);
    % e5=mb.body.eye.Navarro('accommodation',5,'color',[1 0 0 1]);
    %   e0=mb.body.eye.Arizona('accommodation',0,'color',[0 0 0 1],'pupil_diam',3,'linewidth',2);
    % e5=mb.body.eye.Arizona('accommodation',5,'color',[1 0 0 1],'pupil_diam',3,'linewidth',2);
    e0=mb.body.eye.GullstrandVar('accommodation',0,'color',[0 0 0 1],'pupil_diam',3,'linewidth',2);
    e5=mb.body.eye.GullstrandVar('accommodation',5,'color',[1 0 0 1],'pupil_diam',3,'linewidth',2);
    e5.show;
    hold on
    e0.show;

    mb.library.Plot.find_fig('Scene');
    %% Parameters
    parms.fovea_alpha=0;
    parms.n_rays_per_light=51;
    parms.light_dpt=1;
    
    %% Create a light source
    light=mb.Light('color','r','linewidth',1);
    light.xpos=cosd(parms.fovea_alpha)*1000/parms.light_dpt;
    light.ypos=sind(parms.fovea_alpha)*1000/parms.light_dpt;
    light.aim_rays_at_line_segment(parms.n_rays_per_light,[0;-4],[0;4]);
    
    %% Create an eyeball
    %eye=mb.body.eye.Navarro;
    eye=mb.body.eye.Arizona;
    eye.accommodation = parms.light_dpt;
    eye.pupil_diam = 3;
    eye.pupil_offset = 0;
    
    %% Combine into a scene
    scene=mb.Scene;
    scene.add_light(light);
    scene.add_body(eye);
    
    %% Trace the light rays
    scene.shine;
    scene.show;
    axis manual
    set(gca,'YLim',[-50 50])
    set(gca,'XLim',[-50 1050])
    title('Light source at 1.0 dpt')
end
