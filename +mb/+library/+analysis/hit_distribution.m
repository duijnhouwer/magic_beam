
function [hit_theta,hit_world_xy,hit_arc] = hit_distribution(rays,arc)
   

    % hit_theta = hit_distribution(rays,arc)
    % Return distribution of rays hitting the arc, in arc coordinates (degrees)
    %
    % [~,hit_world_xy] = hit_distribution(rays,arc)
    % Return distribution of rays hitting the arc, in world coordinates (x,y) in mm
    %
    % [~,~,hit_arc] = hit_distribution(rays,arc)
    % Return distribution of rays hitting the arc in arc coordinates (mm)
    %
    % Note: 'hit_distribution as of yet only implemented for objects of class mb.arc'

    errstr="";
    if ~isa(rays,'mb.Ray')
        errstr=errstr+"Arg1 must be an array of objects of class 'mb.Ray.'";
    end
    if ~isa(arc,'mb.boundary.Arc')
        errstr=errstr+" Arg2 must be an object of class 'mb.boundary.Arc.'";
    end
    error(strtrim(errstr));

    cx = arc.xpos;
    cy = arc.ypos;
    r1 = arc.radius;
    r2 = arc.radius2;
    reference_theta =arc.arc_delta+arc.orientation;

    hit_world_xy=nan(2,numel(rays));
    hit_theta=nan(1,numel(rays)); % ray impact in retinal coordinate in degrees
    if nargout>2
        hit_arc=nan(1,numel(rays)); % ray impact in retinal coordinate in mm
    end
    for i=1:numel(rays)
        if rays(i).lineage.deathplace==arc.id
            hit_world_xy(1,i) = rays(i).xpos+cosd(rays(i).orientation)*rays(i).length;
            hit_world_xy(2,i) = rays(i).ypos+sind(rays(i).orientation)*rays(i).length;
            hit_theta(i) = mod(atan2d(hit_world_xy(2,i)-cy,hit_world_xy(1,i)-cx),360);
            if nargout>2
                hit_arc(i) = mb.library.Math.ellipse_arc_length(r1,r2,0,hit_theta(i));
            end
        end
    end
    % Remove all nans from output
    hit_theta(isnan(hit_theta))=[];
    % make hit_theta relative to the reference orientation
    hit_theta = mod(hit_theta-reference_theta,360)-180;
    hit_theta = hit_theta-180;
    hit_theta(hit_theta<-180)=hit_theta(hit_theta<-180)+360; % express with reference theta a 0 and clockwise from that being negative and ccw from that being positive
    if nargout>1
        hit_world_xy(:,isnan(hit_world_xy(1,:)))=[];
        if nargout>2
            hit_arc(isnan(hit_arc))=[];
        end
    end
end
