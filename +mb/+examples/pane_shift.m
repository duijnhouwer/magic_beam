function pane_shift
    
    
    clf(qx.find_fig(mfilename));
    mb.settings('reflex',false)
    
    scene=mb.Scene;
    
    screen=mb.body.Rect;
    screen.r1r2=[1 0];
    screen.height=5;
    screen.width=100;
    screen.ypos=40;
 % scene.add_body(screen);
    
    %% without ML1
  %  light_wout=mb.Light('ray_angles',linspace(120,60,3));
  %  light_wout.color='b';
  %  scene.add_light(light_wout)
  %  scene.shine
  %  scene.show
    
    hold on
    
    %% with ML1
    pane=mb.body.Rect;
    pane.height=5;
    pane.width=40;
    pane.ypos=25;
    
    
    
    light_with=mb.Light('ray_angles',linspace(120,60,3));
    light_wout.color='b';
    
    scene.add_body(pane);
    scene.add_light(light_with);
    
    
    scene.shine
    scene.show
    
end