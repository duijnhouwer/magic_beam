%% base - Base class for all Magic Beam objects.
% Also see: mb.base.Visible
classdef (Abstract) Base < matlab.mixin.SetGet ...
        & matlab.mixin.Copyable ... % allows to make *shallow* copies of instances
        & mb.library.Math ...
        & mb.library.Misc
   
    properties (Hidden,GetAccess=public,SetAccess=protected)
        id % Unique ID for all instances of derived classes
    end
    
    methods
        %% constructor
        function O=Base
            O.id = mb.library.Misc.unique_id;
        end
    end
    
end