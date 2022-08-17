classdef (Abstract) Plot < handle
    
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
    end
end