function out = settings(varargin)
    
    % Function to set and retrieve magic_beam settings
    %
    % Examples:
    %   Return setting for verbosity
    %       mb.settings('verbose') 
    %
    %   Turn off reflections:
    %       mb.settings('reflex',false)
    %
    %       mb.settings('refract',true,'reflex',false,'verbose',0) % set multiple settings at once
    %
    %   Returns all current settings as a structure
    %       str = mb.settings
    %
    %   Change the structure and use it as input to set settings
    %       str.reflex=false
    %       mb.settings(str)
    %
    %   Start 8 parallel pool workers. If the requested number is different
    %   than the currently available number of workers, existing workers are
    %   deleted and the requested number started:
    %       mb.settings('n_workers',8)
    %
    %   Set all settings back to default:
    %       mb.settings('factory_reset')
    %
    %   Note: mb.settings('factory_reset') as a side effect also calls
    %   mb.library.Misc.unique_id("reset_counter") which reset the function that returns
    %   unique IDs for each object in the run. This should never be called during a run,
    %   only at the very beginning.
    
    persistent s
    if isempty(s)
        s = default_settings;
    end
    
    if nargin==1
        arg=varargin{1};
        if ischar(arg) || isstring(arg)
            arg=lower(arg);
            if strcmp(arg,'factory_reset')
                % Set all settings back to default
                s = default_settings;
                out = s;
                mb.library.Misc.unique_id("reset_counter");
            else
                out = s.(arg);
            end
        elseif isstruct(arg)
            % Set the settings using a struct. First check if it's valid
            names=fieldnames(arg);
            vals=struct2cell(arg);
            name_vals=[names(:)'; vals(:)'];
            s = parse_name_value_list(name_vals);
            out = s;
        else
            error('When using settings with a single argument it should be a string or a struct');
        end
    elseif nargin==0
        % Return a struct with all current settings
        out=s;
    elseif mod(nargin,2)==0
        s=parse_name_value_list(varargin{:});
        out=s;
    else
        error('0, 1, or an even number of inputs required')
    end 
end

function s=default_settings
    s=parse_name_value_list;
end

function out=parse_name_value_list(varargin)
    % Settings and their factory defaults are specified here
    p=inputParser;
    p.addParameter('refract',1,@(x)islogical(x) || isnumeric(x) && x==0 || x==1);
    p.addParameter('reflex',1,@(x)islogical(x) || isnumeric(x) && x==0 || x==1);
    p.addParameter('verbose',0,@(x)islogical(x) || isnumeric(x) && x>=0 && x<=5 && rem(x,1)==0);
    p.addParameter('n_workers',[],@(x)isempty(x) || isnumeric(x) && isscalar(x) && x>=0 && rem(x,1)==0); % empty means leave as is
    p.addParameter('fontsize',18,@(x)isnumeric(x) && isscalar(x) && x>=0);
    p.addParameter('infinite_ray_display_length',30,@(x)isnumeric(x) && isscalar(x) && x>=0);
    p.addParameter('length_unit','mm',@(x)ischar(x) || isstring(x));
    p.parse(varargin{:});
    out=p.Results;  
    out=direct_actions(out);
end

function out=direct_actions(out)
    % Settings with direct consequences should be processed here
    
    % Start parallel pools to match requested number of workers
    if ~isempty(out.n_workers)  % empty means leave as is
        mb.library.Misc.start_parallel_worker_pool(out.n_workers);
    end
end
    
    
    
    
    
    