classdef Plot < handle

    % Library of support functions for plotting. Support function of
    % a general mathematical nature are in mb.library.Math
    %
    % This is similar to having a subfolder with help functions, but i think
    % it's neater to have all these functions bundled into one file as static
    % methods.
    %
    % methods(mb.library.Plot) prints a list of all methods
    %
    % help mb.library.Plot.NAMEOFMETHOD displays the help of method
    %
    % See also: mb.library.Math, mb.library.Analysis, mb.library.Misc

    % Jacob Duijnhouwer 2021-03-09


    methods (Static)
        function [fig,denovo]=find_fig(name,varargin)
            % Select or create a figure by name
            fig=findobj('Type','figure','Name',name);
            denovo=isempty(fig); % does not exist yet, create
            if denovo
                fig=figure('Name',name,varargin{:});
                % did the use specify if they wanted a figure number ahead of the name or not? if not specified,
                % enforce a default of 'NumberTitle','off'. That is, show the name only, not: 'Figure X: name'
                if isempty(varargin) || ~any(strcmpi(varargin,'NumberTitle'))
                    fig.NumberTitle='off';
                end
                fig.Color=[1 1 1];
            else
                figure(fig); % simply bring existing figure to front
            end
        end

        function [intensity,xx,yy] = rasterize_rays(varargin)
            % Rasterize rays for plotting as surf or image
            p=inputParser;
            p.addParameter('rays',[],@(x)isa(x,'mb.Ray'));
            p.addParameter('axis',gca);
            p.addParameter('xlim',[],@(x)isnumeric(x)&&numel(x)==2);
            p.addParameter('ylim',[],@(x)isnumeric(x)&&numel(x)==2);
            p.addParameter('pxsize',0.2,@(x)isnumeric(x)&&x>0);
            p.addParameter('pxwidth',[],@(x)isnumeric(x)&&x>0);
            p.addParameter('pxheight',[],@(x)isnumeric(x)&&x>0);
            p.addParameter('thickness',1,@(x)isnumeric(x)&&x>0);
            p.addParameter('target','image',@(x)any(strcmpi(x,{'image','surf'})));
            p.parse(varargin{:});

            % Unpack parser
            rays=p.Results.rays;
            if isempty(p.Results.xlim)
                xmin=min(p.Results.axis.XLim);
                xmax=max(p.Results.axis.XLim);
            else
                xmin=min(p.Results.xlim);
                xmax=max(p.Results.xlim);
            end
            if isempty(p.Results.ylim)
                ymin=min(p.Results.axis.YLim);
                ymax=max(p.Results.axis.YLim);
            else
                ymin=min(p.Results.ylim);
                ymax=max(p.Results.ylim);
            end
            if ~isempty(p.Results.pxsize)
                pxwid=p.Results.pxsize;
                pxhei=p.Results.pxsize;
            end
            if ~isempty(p.Results.pxwidth)
                pxwid=p.Results.pxsize;
            end
            if ~isempty(p.Results.pxheight)
                pxhei=p.Results.pxsize;
            end

            % Error check the inputs
            errstr="";
            if xmax<=xmin
                errstr=errstr+" right must be greater than left.";
            end
            if xmax<=xmin
                errstr=errstr+" top must be greater than bottom.";
            end
            error(strtrim(errstr));

            % Create the rasterization meshes
            [X,Y]=meshgrid(xmin:pxwid:xmax,ymin:pxhei:ymax);
            pixels=[X(:) Y(:)]';

            % Initialize the intentisy matrix
            intensity=zeros(size(X));

            % calculate the raster's diagonal to use as a "more than long enough"
            % range for those rays that have infinite length
            world_diagonal=hypot(xmax-xmin,ymax-ymin);

            % Calculate the range around the line segments that should activate the
            % intensity matrix's pixels
            max_effect_dist=hypot(pxwid,pxhei)*p.Results.thickness/2;

            for i=1:numel(rays)
                % find the xyz-coordinates of the startpoint (a) and endpoint (b)
                % of the line segment that represents the light ray segment
                a=[rays(i).xpos; rays(i).ypos];
                if ~isfinite(rays(i).length)
                    len=world_diagonal*10;
                else
                    len=rays(i).length;
                end
                b=a+[cosd(rays(i).orientation); sind(rays(i).orientation)]*len;

                % Make the problem trivial by nulling the lines orientation, and
                % rotating the raster pixel coordinates accordingly. Distance to
                % the line is then simply the absolute vertical difference.
                R=mb.library.Math.rotmat(-rays(i).orientation);
                a=R*a;
                b=R*b;
                rotpix=R*pixels;
                dist=abs(rotpix(2,:)-a(2)); % absolute distance of each pixel to the line segment
                roi=dist<max_effect_dist & rotpix(1,:)>=min([a(1) b(1)]) & rotpix(1,:)<=max([a(1) b(1)]); % indices of pixels within range of line segment
                intensity(roi)=intensity(roi)+cos(dist(roi)/max_effect_dist*pi/2.25);
            end

            if strcmpi(p.Results.target,'surf')
                % shift by half a step because surf uses the XY coordinates as the lower left corner of its square bins
                xx=X-pxwid/2;
                yy=Y-pxhei/2;
            elseif strcmpi(p.Results.target,'image')
                xx=xmin:pxwid:xmax;
                yy=ymin:pxhei:ymax; 
            else
                error('unknown target: %s',p.Results.target);
            end
        end
    end
end