classdef (Abstract) Misc < handle
    
    % Library of support functions specific to Magic Beam. Support function of
    % a general mathematical nature are in mb.library.Math
    %
    % This is similar to having a subfolder with help functions, but i think
    % it's neater to have all these functions bundled into one file as static
    % methods (method is object-oriented equivalent of a function)
    %
    % methods(mb.library.Misc) prints a list of all methods
    %
    % help mb.library.Misc.NAMEOFMETHOD displays the help of method
    %
    % See also: mb.library.Math, mb.library.Analysis, mb.library.Plot
    
    % Jacob Duijnhouwer 2021-02-05
    
    methods (Static)
        function fprintf(varargin)
            % Variant of builtin fprintf that only prints when
            % mb.settings('verbose') is true
            if mb.settings('verbose')
                fprintf(varargin{:});
            end
        end
        
        function b=copy(a)
            % Variant of builtin copy that's ok with empty input
            if isempty(a)
                b=[];
            else
                b=copy(a);
            end
        end
        
        function name = auto_fieldname(s,stem,ndigits)
            % Generate a new field to struct 's' that starts with string 'stem' followed by a unique
            % number. Optional 'ndigits' formats the number, for example, if 'ndigits' is 3, the names
            % will be of format stem001, stem002, etc. Note that if the number exceeds 999, the next
            % fieldnames will simply be stem1000, stem1001, etc. without throwing an error.
            if nargin==2
                ndigits=0;
            end
            str=sprintf('%s%%.%dd',stem,ndigits); % e.g. 'stem%.3d'
            for i=1:intmax('int64')-1
                name=sprintf(str,i);
                if ~isfield(s,name)
                    break;
                end
            end
            if i==intmax('int64')-1
                % If the body of the above for loop takes 3 microseconds, it would take us about
                % a million years to get here. Just in case, here is an error:
                error('Too many fields.');
            end
        end
        
        function id = unique_id(reset)
            % Returns ever increasing numbers between 0 and 1.8447e+19-1 This should be enough
            % for any run. Number only reset after restarting matlab or by calling
            % unique_id("reset_counter")
            %
            % Make sure to never call unique_id("reset_counter") during a run, only at the very beginning!
            
            persistent counter
            if nargin==1
                if strcmpi(reset,'reset_counter')
                    counter = uint64(0);
                    return;
                else
                error('arg1 should be omitted or be this string "reset_counter"');
                end
            end   
            if isempty(counter)
                counter = uint64(0);
            end
            counter = counter + 1;
            id = counter;
        end
        
%         function [ax, varargin] = skim_axes(varargin)
%             %% skim_axes - Strip axes arguments from a "varargin" list.
%             % Returns a new axes-object if there was none in the list
%             % Make sure to call with varargin expanded, like this: skim_axes(varargin{:})
%             
%             ax_idx=cellfun(@(x)isa(x,'matlab.graphics.axis.Axes') || isa(x,'matlab.ui.control.UIAxes'),varargin);
%             if sum(ax_idx)>1
%                 error('There are multiple axes objects among the arguments');
%             elseif any(ax_idx)
%                 ax=varargin{ax_idx};
%                 varargin(ax_idx)=[]; % remove it from the arguments
%             else
%                 ax=gca; % Select current axes or create new ones if there are none
%             end
%         end
%         
        function n_workers = start_parallel_worker_pool(n_workers)
            % Start a pool of 'n_workers' parallel workers. Checks to see if n_workers
            % are already open so it only needs to (re)start them if the number is
            % different.
            narginchk(1,1);
            try
                poolobj = gcp('nocreate');
                if isempty(n_workers) % only report current number of active workers
                    if isempty(poolobj)
                        n_workers = 0;
                    else
                        n_workers=poolobj.NumWorkers;
                    end
                    return
                elseif isempty(poolobj) && n_workers>0
                    parpool(n_workers,'IdleTimeout',24*60);
                elseif ~isempty(poolobj) && n_workers~=poolobj.NumWorkers
                    delete(poolobj);
                    if n_workers>0
                        parpool(n_workers,'IdleTimeout',24*60);
                    end
                end
            catch me
                fprintf('[%s] %s\n',mfilename,me.message);
                fprintf('[%s] n_workers is set to 0\n',mfilename);
                delete(poolobj)
                n_workers=0;
            end
        end
        
        
        function rgb = wrgbcmyk_to_rgb(c)
            % Convert single-letter color codes to RGB triplets
            narginchk(1,1);
            s=struct('w',[1 1 1],'r',[1 0 0],'g',[0 1 0],'b',[0 0 1],'c',[0 1 1],'m',[1 0 1],'y',[1 1 0],'k',[0 0 0]);
            try
                rgb=s.(lower(c));
            catch
                error('input must be ''w'', ''r'', ''g'', ''b'', ''c'', ''m'', ''y'', or ''k''');
            end
        end
        
        function str=seconds_to_readable(seconds,format)      
            % str=seconds_to_readable(seconds,format)
            % Return a legible time format string.
            %
            % Example:
            % h=tic; pause(2);
            % fprintf('Example finished in %sstr=seconds_to_readable(toc(h)));
            %
            % Jacob 2011-10-18
            
            if seconds<1
                str='less than a second';
                return;
            end
            seconds=round(seconds);
            
            if nargin==1
                format='shortest';
            end
            
            % function handle to return a plural s if x>1
            pop_s=@(x)repmat('s',x>1,1);
            
            if strcmpi(format,'shortest')
                weeks=floor(seconds/3600/24/7);
                remainder=rem(seconds,3600*24*7);
                days=floor(remainder/3600/24);
                remainder=rem(seconds,3600*24);
                hours=floor(remainder/3600);
                remainder=rem(seconds,3600);
                mins=floor(remainder/60);
                secs=rem(remainder,60);
                if weeks>0
                    str=sprintf('%d week%s %d day%s %d hour%s %d minute%s %d second%s',weeks,pop_s(weeks),days,pop_s(days),hours,pop_s(hours),mins,pop_s(mins),secs,pop_s(secs));
                elseif days>0
                    str=sprintf('%d day%s %d hour%s %d minute%s %d second%s',days,pop_s(days),hours,pop_s(hours),mins,pop_s(mins),secs,pop_s(secs));
                elseif hours>0
                    str=sprintf('%d hour%s %d minute%s %d second%s',hours,pop_s(hours),mins,pop_s(mins),secs,pop_s(secs));
                elseif mins>0
                    str=sprintf('%d minute%s %d second%s',mins,pop_s(mins),secs,pop_s(secs));
                else
                    str=sprintf('%d second%s',secs,pop_s(secs));
                end
            else
                error(['Unknown format: ' format]);
            end
        end
        
        function apply_name_value_pairs(O,nvpairs)
            %apply_name_value_pairs(O,nvpairs)
            %   Update the properties in object O with the values in nvpairs. nvpairs
            %   is a cell array of name-value pairs where the name-strings must
            %   correspond to the names of the properties of object O. Checking of
            %   validity of the values can (should) be taken care of in the set methods
            %   of classfile of O. This function typically used in the contructor of a
            %   class so that it's possible to instantiate like this.
            %
            %   Examples: assuming rect is some class that creates a rectangle with a
            %   some width and a height, then R=rect('width',10,'height',20) instanties
            %   a 10x20 rect. R=rect('width',10,'height',[]) would leave height to the
            %   default defined in the properties block of rect. This is equivalent to
            %   calling R=rect('width',10]).
            %
            %   If rect inherits matlab.mixin.SetGet than its possible to use partial
            %   mathcing, e.g. R=rect('w',100) is equivalent to R=rect('width',100) 
            %
            %   Update 2021-08-22: nvpairs can now also be a struct
            
            %% Parse the input
            narginchk(2,2);
            if iscell(nvpairs) && numel(nvpairs)==1
                nvpairs=nvpairs{1};
            end
            if ~isstruct(nvpairs) && ~(iscell(nvpairs) && mod(numel(nvpairs),2)==0)
                error('nvpairs must be a struct, or a cell containing that struct, or a cell array with an even number of elements');
            end
            if isstruct(nvpairs)
                vars=fieldnames(nvpairs);
                vals=struct2cell(nvpairs);
            else
                vars=nvpairs(1:2:end);
                vals=nvpairs(2:2:end);
            end
            %% Apply the values
            for i=1:numel(vars)
                if ~isempty(vals{i}) % empty means "keep default value"
                    set(O,(vars{i}),vals{i}); % using set(O,name,value) instead O.(name)=value allows partial matching
                end
            end
        end
        
    end
end
