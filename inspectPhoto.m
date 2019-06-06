%% Follicle Finder - Recognize trachomatous follicles in eyelid photographs
%  Copyright (C) 2019 Luca Della Santina
%
% TODO: move zoom region if user selected listbox item out of field of view
% The painting radius seems to be working when I adjust the denominator of the Res/72 according to the screen dimensions. 26 worked for the widescreen on my desk while 36 worked for the square screen. 
% Also, the viewport seems to get real wacky when trying to do the right-click to center the focus of the zoom. This is an issue I'd like to show you in person because it's a little complicated to articulate over email. 
% Finally, I was unsure if this was deliberate, but the "maybe" dots don't show up unless selected.
function Dots = inspectPhoto(Img, Dots, Prefs)
    % Default parameter values
    CutNumVox   = ceil(size(Img)/Prefs.Zoom); % Size of zoomed region    
    Pos         = [ceil(size(Img,2)/2), ceil(size(Img,1)/2)]; % Initial mouse position
    PosRect     = [ceil(size(Img,2)/2-CutNumVox(2)/2), ceil(size(Img,1)/2-CutNumVox(1)/2)]; % Initial position of zoomed rectangle (top-left vertex)
    PosZoom     = [-1, -1]; % Mouse position inside the zoomed area
	click       = 0;        % Initialize click status
    SelObjID    = 0;        % Initialize selected object ID#
    actionType  = Prefs.actionType; % Mode of operation
    analysisDone= false;    % Flag to determine if we should close the UI
	
	% Initialize GUI
	fig_handle = figure('Name','Photo inspector (click locations on right panel to add follicles)','NumberTitle','off','Color',[.3 .3 .3], 'MenuBar','none', 'Units','norm', ...
		'WindowButtonDownFcn',@button_down, 'WindowButtonUpFcn',@button_up, 'WindowButtonMotionFcn', @on_click, 'KeyPressFcn', @key_press,'windowscrollWheelFcn', @wheel_scroll, 'CloseRequestFcn', @closeRequest);

    % Add GUI conmponents
    set(gcf,'units', 'normalized', 'position', [0.05 0.1 0.90 0.76]);
    pnlSettings     = uipanel(  'Title',''          ,'Units','normalized','Position',[.903,.005,.095,.99]); %#ok, unused variable
    txtValidObjs    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.940,.085,.02],'String',['Total: ' num2str(numel(find(Dots.Filter)))]);
    txtAction       = uicontrol('Style','text'      ,'Units','normalized','position',[.912,.905,.020,.02],'String','Tool:'); %#ok, unused handle
    cmbAction       = uicontrol('Style','popup'     ,'Units','normalized','Position',[.935,.890,.055,.04],'String', {'Add (a)', 'Refine (r)','Select (s)', 'Enclose(e)'},'Callback', @cmbAction_changed);
    chkShowObjects  = uicontrol('Style','checkbox'  ,'Units','normalized','position',[.912,.870,.085,.02],'String','Show (spacebar)', 'Value',1,'Callback',@chkShowObjects_changed);
    lstDots         = uicontrol('Style','listbox'   ,'Units','normalized','position',[.907,.600,.085,.25],'String',[],'Callback',@lstDots_valueChanged);
    txtZoom         = uicontrol('Style','text'      ,'Units','normalized','position',[.925,.260,.050,.02],'String','Zoom level:'); %#ok, unused variable
    btnZoomOut      = uicontrol('Style','Pushbutton','Units','normalized','position',[.920,.200,.030,.05],'String','-','Callback',@btnZoomOut_clicked); %#ok, unused variable
    btnZoomIn       = uicontrol('Style','Pushbutton','Units','normalized','position',[.950,.200,.030,.05],'String','+','Callback',@btnZoomIn_clicked); %#ok, unused variable
    txtDiagnosis    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.125,.085,.02],'String','Diagnosis:'); %#ok, unused variable
    cmbDiagnosis    = uicontrol('Style','popup'     ,'Units','normalized','Position',[.912,.080,.080,.04],'String', {'Normal','TF','TI','TT','CO'},'Callback', @cmbDiagnosis_changed);
    btnSave         = uicontrol('Style','Pushbutton','Units','normalized','position',[.907,.020,.088,.05],'String','Done','Callback',@btnSave_clicked); %#ok, unused variable    
    
    % Selected object info
    btnDelete       = uicontrol('Style','Pushbutton','Units','normalized','position',[.907,.560,.088,.04],'String','Delete Item (d)','Callback',@btnDelete_clicked); %#ok, unused variable
    txtSelObj       = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.530,.085,.02],'String','Selected item'); %#ok, unused variable
    txtSelObjID     = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.500,.085,.02],'String','ID# :');
    txtSelObjPos    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.470,.085,.02],'String','Pos : ');
    txtSelObjPix    = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.440,.085,.02],'String','Pixels : ');
    txtSelObjValid  = uicontrol('Style','text'      ,'Units','normalized','position',[.907,.410,.085,.02],'String','Type : ');    
    btnValidate     = uicontrol('Style','Pushbutton','Units','normalized','position',[.907,.360,.088,.04],'String','Change validation (v)','Callback',@btnValidate_clicked); %#ok, unused variable
    
	% Main drawing axes for video display
    size_video = [0 0 0.90 1];
    if size_video(2) < 0.03
        size_video(2) = 0.03;
    end % bottom 0.03 will be used for scroll bar HO 2/17/2011
	axes_handle = axes('Position',size_video);
	frame_handle = 0;
    rect_handle = 0;
    
    lstDotsRefresh;
    cmbAction_assign(actionType);
    cmbDiagnosis_assign(Dots.Diagnosis);
    refreshRightPanel;
    brushSize = 20;
    brush = line('linestyle', 'none', 'MarkerSize', brushSize, 'marker', 'o', 'MarkerEdgeColor', 'black'); % Handle of custom mouse cursor
    animatedLine = animatedline('LineWidth', 1, 'Color', 'blue');
    uiwait;
    
    function closeRequest(src,event) %#ok unused parameters
        if ~analysisDone
            Dots = [];
        end
        delete(fig_handle);
    end

    function btnSave_clicked(src, event)
        analysisDone = true;
        closeRequest(src,event);
    end

    function cmbAction_changed(src,event) %#ok, unused parameters
        switch get(src,'Value')
            case 1, actionType = 'Add';                
            case 2, actionType = 'Refine';
            case 3, actionType = 'Select';
            case 4, actionType = 'Enclose';
        end
    end

    function cmbAction_assign(newType)
        switch newType
            case 'Add',     set(cmbAction, 'Value', 1);                
            case 'Refine',  set(cmbAction, 'Value', 2);
            case 'Select',  set(cmbAction, 'Value', 3);
            case 'Enclose', set(cmbAction, 'Value', 4);
        end
    end

    function cmbDiagnosis_changed(src, event) %#ok, unused parameters
        switch get(src, 'Value')
            case 1, Dots.Diagnosis = 'Normal';
            case 2, Dots.Diagnosis = 'TF';
            case 3, Dots.Diagnosis = 'TI';
            case 4, Dots.Diagnosis = 'TT';
            case 5, Dots.Diagnosis = 'CO';
        end
    end

    function cmbDiagnosis_assign(newDiagnosis)
        switch newDiagnosis
            case 'Normal',  set(cmbDiagnosis, 'Value', 1);                
            case 'TF',      set(cmbDiagnosis, 'Value', 2);
            case 'TI',      set(cmbDiagnosis, 'Value', 3);
            case 'TT',      set(cmbDiagnosis, 'Value', 4);
            case 'CO',      set(cmbDiagnosis, 'Value', 5);
        end
    end

    function lstDots_valueChanged(src,event) %#ok, unused arguments
        SelObjID = get(src, 'Value');
        if SelObjID > 0 && numel(Dots.Filter)>0
            set(txtSelObjID    ,'string',['ID#: ' num2str(SelObjID)]);
            set(txtSelObjPos   ,'string',['Pos X:' num2str(Dots.Pos(SelObjID,1)) ', Y:' num2str(Dots.Pos(SelObjID,2))]);
            set(txtSelObjPix   ,'string',['Pixels : ' num2str(numel(Dots.Vox(SelObjID).Ind))]);
            switch Dots.Filter(SelObjID)
                case 1,  set(txtSelObjValid ,'string','Type : True');
                case -1, set(txtSelObjValid ,'string','Type : False');
                case 0,  set(txtSelObjValid ,'string','Type : Maybe');
            end
        else
            set(txtSelObjID    ,'string','ID#: '       );
            set(txtSelObjPos   ,'string','Pos : '    );
            set(txtSelObjPix   ,'string','Pixels : '   );
            set(txtSelObjValid ,'string','Type : ');
        end
        refreshRightPanel;
    end

    function btnDelete_clicked(src,event) %#ok, unused arguments
        if SelObjID > 0
            Dots.Pos(SelObjID, :) = [];
            Dots.Vox(SelObjID)    = [];
            Dots.Filter(SelObjID) = [];
            SelObjID = numel(Dots.Filter);

            lstDotsRefresh;            
            set(lstDots, 'Value', 1);
            PosZoom = [-1, -1];
            refreshRightPanel;    
        end
    end

    function btnValidate_clicked(src,event) %#ok, unused arguments
        if SelObjID > 0
            switch Dots.Filter(SelObjID)
                case 0, Dots.Filter(SelObjID)   = 1;
                case 1, Dots.Filter(SelObjID)   = -1;
                case -1, Dots.Filter(SelObjID)  = 0;
            end

            
            set(lstDots, 'Value', SelObjID);
            lstDots_valueChanged(lstDots, event);
            PosZoom = [-1, -1];
            refreshRightPanel;    
        end
    end
    function lstDotsRefresh
        % Update list of available ROIs
        set(lstDots, 'String', 1:numel(Dots.Filter));
        set(txtValidObjs,'string',['Total: ' num2str(numel(find(Dots.Filter)))]);
        if SelObjID > 0
            PosZoom = [Dots.Pos(SelObjID, 2), Dots.Pos(SelObjID, 1)];      
        end
        refreshRightPanel;
    end

    function ID = addDot(X, Y, R)
        % Compute the actual radius from zoomed region scaling factor
        scaling = size(Img,1) / CutNumVox(1);
        r = R / scaling;
        
        % Create a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask = (x-X).^2 + (y-Y).^2 < r.^2;
        
        % Generate statistics of the new dot and add to Dots
        if isempty(Dots.Pos)
            Dots.Pos(1,:)       = [X,Y];            
            Dots.Vox(1).Ind        = find(mask);
            [Dots.Vox(1).Pos(:,1), Dots.Vox(1).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(1).Ind);            
            Dots.Filter         = 1;
        else
            Dots.Pos(end+1,:)   = [X,Y];
            Dots.Vox(end+1).Ind = find(mask);
            [Dots.Vox(end).Pos(:,1), Dots.Vox(end).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(end).Ind);            
            Dots.Filter(end+1)  = 1;
        end
        
        SelObjID = numel(Dots.Filter);
        ID = SelObjID;
        lstDotsRefresh;
    end

    function addPxToDot(X, Y, R, ID)
        % Compute the actual radius from zoomed region scaling factor
        scaling = size(Img,1)/CutNumVox(1);
        r = R/scaling;
        
        % Create a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask = (x-X).^2 + (y-Y).^2 < r.^2;

        % Add new pixels to those belonging to Dot #ID
        if ID > 0
            Dots.Vox(ID).Ind = union(Dots.Vox(ID).Ind, find(mask), 'sorted');
            Dots.Vox(ID).Pos = [];
            [Dots.Vox(ID).Pos(:,1), Dots.Vox(ID).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(ID).Ind);            
        end        
    end

    function addPolyAreaToDot(xv, yv, ID)
        % Switch mouse pointer to hourglass while computing
        oldPointer = get(fig_handle, 'Pointer');
        set(fig_handle, 'Pointer', 'watch'); pause(0.3);

        % Create mask inside the passed polygon coordinates
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask = inpolygon(x,y,xv,yv);

        % Add new pixels to those belonging to Dot #ID
        if ID == 0
            ID = addDot(ceil(mean(xv)),ceil(mean(yv)),5);
        end
        
        if ID > 0
            Dots.Vox(ID).Ind = union(Dots.Vox(ID).Ind, find(mask), 'sorted');
            Dots.Vox(ID).Pos = [];
            [Dots.Vox(ID).Pos(:,1), Dots.Vox(ID).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(ID).Ind);            
        end        
        set(fig_handle, 'Pointer', oldPointer);        
    end

    function removePxFromDot(X, Y, R, ID)
        % Compute the actual radius from zoomed region scaling factor
        scaling = size(Img,1)/CutNumVox(1);
        r = R/scaling;
        
        % Create a circular mask around the pixel [xc,yc] of radius r
        [x, y] = meshgrid(1:size(Img,2), 1:size(Img,1));
        mask = (x-X).^2 + (y-Y).^2 < r.^2;

        % Add new pixels to those belonging to Dot #ID
        if ID > 0
            Dots.Vox(ID).Ind = setdiff(Dots.Vox(ID).Ind, find(mask), 'sorted');
            Dots.Vox(ID).Pos = [];
            [Dots.Vox(ID).Pos(:,1), Dots.Vox(ID).Pos(:,2)] = ind2sub(size(Img), Dots.Vox(ID).Ind);            
        end        
    end

    function chkShowObjects_changed(src,event) %#ok, unused arguments
        refreshRightPanel;
    end

    function btnZoomOut_clicked(src, event) %#ok, unused arguments
        ImSize = [size(Img,1), size(Img,2)];
        CutNumVox = [min(CutNumVox(1)*2, ImSize(1)), min(CutNumVox(2)*2, ImSize(2))];
        PosRect   = [ceil(size(Img,2)/2-CutNumVox(2)/2), ceil(size(Img,1)/2-CutNumVox(1)/2)]; % Initial position of zoomed rectangle (top-left vertex)        
        PosZoom   = [-1, -1];
        refreshBothPanels;
    end

    function btnZoomIn_clicked(src, event) %#ok, unused arguments
        CutNumVox = [max(round(CutNumVox(1)/2,0), 32), max(round(CutNumVox(2)/2,0),32)];
        PosRect   = [ceil(size(Img,2)/2-CutNumVox(2)/2), ceil(size(Img,1)/2-CutNumVox(1)/2)]; % Initial position of zoomed rectangle (top-left vertex)        
        PosZoom   = [-1, -1];
        refreshBothPanels;
    end

    function wheel_scroll(src, event)
          if event.VerticalScrollCount < 0              
              brushSize = brushSize +1;
          elseif event.VerticalScrollCount > 0             
              brushSize = brushSize -1;
              if brushSize < 1, brushSize = 1; end
          end
          click = 0;
          on_click(src, event);
    end
    
    function key_press(src, event) %#ok missing parameters
        switch event.Key  % Process shortcut keys
            case 'space'
                chkShowObjects.Value = ~chkShowObjects.Value;
                chkShowObjects_changed();
            case 'a'
                set(cmbAction, 'Value', 1); 
                cmbAction_changed(cmbAction, event);
            case 'r'
                set(cmbAction, 'Value', 2); 
                cmbAction_changed(cmbAction, event);
            case 's'
                set(cmbAction, 'Value', 3); 
                cmbAction_changed(cmbAction, event);
            case 'e'
                set(cmbAction, 'Value', 4); 
                cmbAction_changed(cmbAction, event);                
            case 'd'
                btnDelete_clicked();
            case {'leftarrow'}
                Pos = [max(CutNumVox(2)/2, Pos(1)-CutNumVox(1)+ceil(CutNumVox(2)/5)), Pos(2)];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case {'rightarrow'}
                Pos = [min(size(Img,2)-1-CutNumVox(2)/2, Pos(1)+CutNumVox(2)-ceil(CutNumVox(2)/5)), Pos(2)];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case {'uparrow'}
                Pos = [Pos(1), max(CutNumVox(1)/2, Pos(2)-CutNumVox(1)+ceil(CutNumVox(1)/5))];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case {'downarrow'}
                Pos = [Pos(1), min(size(Img,1)-1-CutNumVox(1)/2, Pos(2)+CutNumVox(1)-ceil(CutNumVox(1)/5))];
                PosZoom = [-1, -1];
                refreshRightPanel;
            case 'equal' , btnZoomIn_clicked;
            case 'hyphen', btnZoomOut_clicked;
        end
    end

	%mouse handler
	function button_down(src, event)
		set(src,'Units','norm');
		click_posNorm = get(src, 'CurrentPoint');
        set(src,'Units','pixels');
        click_point = get(gca, 'CurrentPoint');
        MousePosX = ceil(click_point(1,1));
        
        if click_posNorm(2) <= 0.035
            click = 1; % click happened on the scroll bar
            on_click(src,event);
        else            
            click = 2; % click happened somewhere else
            on_click(src,event);
        end
	end

	function button_up(src, event)  %#ok, unused arguments
		click = 0;
        click_point = get(gca, 'CurrentPoint');
        MousePosX = ceil(click_point(1,1));

        switch actionType
            case {'Enclose'}
                if MousePosX > size(Img,2)
                    [x,y] = getpoints(animatedLine);

                    % Locate position of points in respect to zoom area
                    PosZoomX = x - size(Img,2)-1;
                    PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                    PosZoomY = size(Img,1) - y;
                    PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));

                    % Locate position of points in respect to original img
                    absX = PosZoomX + PosRect(1);
                    absY = PosZoomY + PosRect(2);

                    % Fill every point within delimited perimeter
                    addPolyAreaToDot(absX, absY, SelObjID);
                end
        end
        refreshRightPanel;
	end

	function on_click(src, event)  %#ok, unused arguments
        if click == 0
            % Set the proper mouse pointer appearance
            set(fig_handle, 'Units', 'pixels');
            click_point = get(gca, 'CurrentPoint');
            PosX = ceil(click_point(1,1));
            PosY = ceil(click_point(1,2));
            
            if PosY < 0 || PosY > size(Img,1)
                % Display the default arrow everywhere else
                set(fig_handle, 'Pointer', 'arrow');
                if isvalid(brush), delete(brush); end 
                return;
            end
            
            if PosX <= size(Img,2)
                % Mouse in Left Panel, display a hand
                set(fig_handle, 'Pointer', 'fleur');
                if isvalid(brush), delete(brush); end                    

            elseif PosX <= size(Img,2)*2
                % Mouse in Right Panel, act depending of the selected tool
                switch actionType
                    case 'Enclose'
                        % Display a crosshair
                        set(fig_handle, 'Pointer', 'crosshair');
                        if isvalid(brush), delete(brush); end 
                        return;
                    case 'Select'
                        %set(fig_handle, 'Pointer', 'arrow');
                        [PCData, PHotSpot] = getPointerCrosshair;
                        set(fig_handle, 'Pointer', 'custom', 'PointerShapeCData', PCData, 'PointerShapeHotSpot', PHotSpot);
                        if isvalid(brush), delete(brush); end 
                    otherwise                        
                        % Display a circle if we are in the right panel
                        set(fig_handle, 'pointer', 'custom', 'PointerShapeCData', NaN(16,16));
                        PosZoom = [-1, -1];

                        % Recreate the brush because frame is redrawn otherwise
                        % just redraw the brush in the new location
                        if ~isvalid(brush)                    
                            brush = line('linestyle', 'none', 'MarkerSize', brushSize, 'marker', 'o', 'MarkerEdgeColor', 'black', 'XData', PosX, 'YData', PosY); % Handle of custom mouse cursor
                        else
                            set(brush, 'MarkerSize',  brushSize,  'XData', PosX, 'YData', PosY);
                        end
                end
            else
                % Display the default arrow everywhere else
                set(fig_handle, 'Pointer', 'arrow');
                if isvalid(brush), delete(brush); end                    
            end                       
        elseif click == 2
            % ** User clicked on the image get XY-coordinates in pixels **
            
            set(fig_handle, 'Units', 'pixels');
            click_point = get(gca, 'CurrentPoint');
            PosX = ceil(click_point(1,1));
            PosY = ceil(click_point(1,2));
            if PosX <= size(Img,2)
                % Make sure zoom rectangle is within image area
                ClickPos = [max(CutNumVox(2)/2+1, PosX),...
                            max(CutNumVox(1)/2+1, PosY)];
                    
                ClickPos = [min(size(Img,2)-CutNumVox(2)/2,ClickPos(1)),...
                            min(size(Img,1)-CutNumVox(1)/2,ClickPos(2))];
                Pos      = ClickPos;
                PosZoom  = [-1, -1];
                PosRect  = [ClickPos(1)-CutNumVox(2)/2, ClickPos(2)-CutNumVox(1)/2];
                refreshLeftPanel;
            else
                % ** User clicked in the right panel (zoomed region) **
                % Detect coordinates of the point clicked in PosZoom
                % Note: x,y coordinates are inverted in ImStk
                % Note: x,y coordinates are inverted in CutNumVox                
                PosZoomX = PosX - size(Img,1)-1;
                PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));
                
                PosZoomY = size(Img,2) - PosY;
                PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));
                
                if ~isvalid(brush)                    
                    brush = line('linestyle', 'none', 'MarkerSize', brushSize, 'Marker', 'o', 'MarkerEdgeColor', 'black', 'XData', PosX, 'YData', PosY); % Handle of custom mouse cursor
                else
                    set(brush, 'Marker', 'o','MarkerSize',  brushSize,  'XData', PosX, 'YData', PosY);
                end
                
                % Do different things depending whether left/right-clicked
                clickType = get(fig_handle, 'SelectionType');                                
                if strcmp(clickType, 'alt')
                    % User RIGHT-clicked in the right panel (zoomed region)
                    switch actionType
                            case {'Add', 'Select', 'Enclose'}
                                % Locate position of points in respect to zoom area
                                PosZoomX = PosX - size(Img,2)-1;
                                PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                                PosZoomY = size(Img,1) - PosY;
                                PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));

                                % Locate position of points in respect to original img
                                absX = PosZoomX + PosRect(1);
                                absY = PosZoomY + PosRect(2);
                                Pos     = [absX,absY];
                                PosZoom = [-1, -1];
                                refreshBothPanels;
                            case 'Refine'
                                % Remove selected pixels from Dot #ID
                                PosZoom = [PosZoomX, PosZoomY];
                                Pos     = [Pos(1), Pos(2)];

                                % Absolute position of pixel clicked on right panel
                                % position Pos. Note: Pos(2) is X, Pos(1) is Y
                                fymin = max(ceil(Pos(2) - CutNumVox(1)/2), 1);
                                fymax = min(ceil(Pos(2) + CutNumVox(1)/2), size(Img,1));
                                fxmin = max(ceil(Pos(1) - CutNumVox(2)/2), 1);
                                fxmax = min(ceil(Pos(1) + CutNumVox(2)/2), size(Img,2));
                                fxpad = CutNumVox(1) - (fxmax - fxmin); % add padding if position of selected rectangle fall out of image
                                fypad = CutNumVox(2) - (fymax - fymin); % add padding if position of selected rectangle fall out of image                    
                                absX  = fxpad+fxmin+PosZoom(1);
                                absY  = fypad+fymin+PosZoom(2);
                                if absX>0 && absX<=size(Img,2) && absY>0 && absY<=size(Img,1)
                                    if ~isvalid(animatedLine)
                                        animatedLine = animatedline('LineWidth', brushSize, 'Color', 'red');
                                    else
                                        addpoints(animatedLine, PosX, PosY); 
                                    end                                     
                                    removePxFromDot(absX, absY, brushSize, SelObjID);
                                end
                    end                   
                elseif strcmp(clickType, 'normal')
                    % User LEFT-clicked in the right panel (zoomed region)
                    PosZoom = [PosZoomX, PosZoomY];
                    Pos     = [Pos(1), Pos(2)];
                                        
                    % Absolute position on image of point clicked on right panel
                    % position Pos. Note: Pos(2) is X, Pos(1) is Y
                    fymin = max(ceil(Pos(2) - CutNumVox(1)/2), 1);
                    fymax = min(ceil(Pos(2) + CutNumVox(1)/2), size(Img,1));
                    fxmin = max(ceil(Pos(1) - CutNumVox(2)/2), 1);
                    fxmax = min(ceil(Pos(1) + CutNumVox(2)/2), size(Img,2));
                    fxpad = CutNumVox(1) - (fxmax - fxmin); % add padding if position of selected rectangle fall out of image
                    fypad = CutNumVox(2) - (fymax - fymin); % add padding if position of selected rectangle fall out of image                    
                    absX  = fxpad+fxmin+PosZoom(1);
                    absY  = fypad+fymin+PosZoom(2);

                    if absX>0 && absX<=size(Img,2) && absY>0 && absY<=size(Img,1)
                        switch actionType
                            case 'Add'
                                % Create a new Dot in this location
                                addDot(absX, absY, brushSize);                                
                            case 'Refine'
                                % Add selected pixels to Dot #ID
                                if ~isvalid(animatedLine)
                                    animatedLine = animatedline('LineWidth', brushSize, 'Color', 'blue');
                                else
                                    addpoints(animatedLine, PosX, PosY); 
                                end 
                                addPxToDot(absX, absY, brushSize, SelObjID);
                            case 'Select'
                                % Locate position of points in respect to zoom area
                                PosZoomX = PosX - size(Img,2)-1;
                                PosZoomX = round(PosZoomX * CutNumVox(2)/(size(Img,2)-1));                
                                PosZoomY = size(Img,1) - PosY;
                                PosZoomY = CutNumVox(1)-round(PosZoomY*CutNumVox(1)/(size(Img,1)-1));
                                PosZoom = [PosZoomX, PosZoomY];
                                
                                % Select the Dot below mouse pointer
                                set(fig_handle, 'CurrentAxes', axes_handle);
                                SelObjID = redraw(chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, 0, Prefs);
                                if SelObjID > 0
                                    set(lstDots, 'Value', SelObjID);
                                end
                            case 'Enclose'
                                set(fig_handle, 'Pointer', 'crosshair');
                                % Add selected pixels to Dot #ID
                                if ~isvalid(animatedLine)
                                    animatedLine = animatedline('LineWidth', 1, 'Color', 'blue');
                                else
                                    addpoints(animatedLine, PosX, PosY); 
                                end 
                        end
                    end
                end

            end
        end
    end


	function refreshBothPanels
        %set to the right axes and call the custom redraw function
		set(fig_handle, 'CurrentAxes', axes_handle);
        set(fig_handle,'DoubleBuffer','off');
		[SelObjID, frame_handle, rect_handle] = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, SelObjID, Prefs, 'both');
        if SelObjID > 0
            set(lstDots, 'Value', SelObjID);
        end
    end
	function refreshRightPanel
        %set to the right axes and call the custom redraw function
		set(fig_handle, 'CurrentAxes', axes_handle);
        set(fig_handle,'DoubleBuffer','off');
		[SelObjID, frame_handle, rect_handle] = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, SelObjID, Prefs, 'right');
        if SelObjID > 0
            set(lstDots, 'Value', SelObjID);
        end
    end
	function refreshLeftPanel
        %set to the right axes and call the custom redraw function
		set(fig_handle, 'CurrentAxes', axes_handle);
        set(fig_handle,'DoubleBuffer','on');
		[SelObjID, frame_handle, rect_handle] = redraw(frame_handle, rect_handle, chkShowObjects.Value, Pos, PosZoom, Img, CutNumVox, Dots, Dots.Filter, SelObjID, Prefs, 'left');
    end
end


function [SelectedObjID, image_handle, navi_handle] = redraw(image_handle, navi_handle, ShowObjects, Pos, PosZoom, Post, NaviRectSize, Dots, Filter, SelectedObjID, Settings, WhichPanel)
%% Redraw function
% Initialize image matrices
f = Post(:,:,1:3);
PostCut = zeros(NaviRectSize(1), NaviRectSize(2), 3, 'uint8');
PostVoxMapCut = PostCut;
PostCutResized = zeros(size(Post,1), size(Post,2), 3, 'uint8');

if (Pos(1) > 0) && (Pos(2) > 0) && (Pos(1) < size(Post,2)) && (Pos(2) < size(Post,1))
    % Identify XY borders of the area to zoom according to passed mouse
    % position Pos. Note: Pos(2) is X, Pos(1) is Y
    fxmin = max(ceil(Pos(2) - NaviRectSize(1)/2), 1);
    fxmax = min(ceil(Pos(2) + NaviRectSize(1)/2), size(Post,1));
    fymin = max(ceil(Pos(1) - NaviRectSize(2)/2), 1);
    fymax = min(ceil(Pos(1) + NaviRectSize(2)/2), size(Post,2));
    fxpad = NaviRectSize(1) - (fxmax - fxmin); % add padding if position of selected rectangle fall out of image
    fypad = NaviRectSize(2) - (fymax - fymin); % add padding if position of selected rectangle fall out of image
    
    % Find which objects are within the zoomed area
    passIcut = Filter;
    for i = 1:numel(passIcut)
        if (Dots.Pos(i,2)>fxmin) && (Dots.Pos(i,2)<fxmax) && (Dots.Pos(i,1)>fymin) && (Dots.Pos(i,1)<fymax)
            %disp('found dot within rect');
            passIcut(i) = 1;
        else
            passIcut(i) = 0;
        end
    end
    
    % Flag voxels of passing objects that are within zoomed area
    VisObjIDs = find(passIcut);
    for i = 1:numel(VisObjIDs)
        switch Filter(VisObjIDs(i))
            case 1,    ColorDot = Settings.ColorValid;
            case 0,    ColorDot = Settings.ColorMaybe;
            case -1,   ColorDot = Settings.ColorFalse;
            otherwise, ColorDot = Settings.ColorValid;
        end
        VoxPos = Dots.Vox(VisObjIDs(i)).Pos;
        for j = 1:size(VoxPos,1)
            if (VoxPos(j,1)>fxmin) && (VoxPos(j,1)<fxmax) && (VoxPos(j,2)>fymin) && (VoxPos(j,2)<fymax)
                %disp('found voxel within selection area');                
                PostVoxMapCut(VoxPos(j,1)+fxpad-fxmin+1,VoxPos(j,2)+fypad-fymin+1,:) = ColorDot;
            end
        end
    end
        
    if SelectedObjID > 0
        % If user clicked an object belonging within the zoomed region, select it
        VoxPos = Dots.Vox(SelectedObjID).Pos;
        %disp(['SelectedObjID: ' num2str(SelectedObjID)]);
        for i = 1:size(VoxPos,1)
            if (VoxPos(i,1)>fxmin) && (VoxPos(i,1)<fxmax) && (VoxPos(i,2)>fymin) && (VoxPos(i,2)<fymax)
                PostVoxMapCut(VoxPos(i,1)+fxpad-fxmin+1, VoxPos(i,2)+fypad-fymin+1, :) = Settings.ColorSelected;
            end
        end
    elseif PosZoom(1)>0 && PosZoom(2)>0
        % If user clicked a location within the zoomed region belonging to an object, select it
        for i=1:numel(VisObjIDs)
            VoxPos = Dots.Vox(VisObjIDs(i)).Pos;
            for j = 1:size(VoxPos,1)
                if ( VoxPos(j,1)==(fxpad+fxmin+PosZoom(2)) ) && (VoxPos(j,2)==(fypad+fymin+PosZoom(1)) )
                    %disp('clicked voxel belongs to a validated object');
                    SelectedObjID = VisObjIDs(i); % Return ID of selected object
                    for k = 1:size(VoxPos,1)
                        % Highlight all voxels belonging to this object
                        PostVoxMapCut(VoxPos(k,1)+fxpad-fxmin+1, VoxPos(k,2)+fypad-fymin+1, :) = Settings.ColorSelected;
                    end
                    break
                end
            end
        end
    end
    
    % Draw the right panel containing a zoomed version of selected area
    PostCut(fxpad+1:fxpad+fxmax-fxmin+1, fypad+1:fypad+fymax-fymin+1,:) = f(fxmin:fxmax, fymin:fymax, :);
    assignin('base', 'PostCut', PostCut);
    assignin('base', 'PostVoxMapCut', PostVoxMapCut);
    if ShowObjects
        PostCutResized = imresize(PostCut,[size(Post,1), size(Post,2)], 'nearest') + imresize(PostVoxMapCut,[size(Post,1), size(Post,2)], 'nearest');
    else
        PostCutResized = imresize(PostCut,[size(Post,1), size(Post,2)], 'nearest');
    end    
    
    % Separate left and right panel visually with a vertical grey line
    PostCutResized(1:end, 1:4, 1:3) = 75;  
end


if image_handle == 0
    % Draw the full image if it is the first time
    image_handle = image(cat(2, f, PostCutResized));
    axis image off
    % Draw a rectangle border over the selected area (left panel)
    navi_handle = rectangle(gca, 'Position',[fymin,fxmin,NaviRectSize(2),NaviRectSize(1)],'EdgeColor', [1 1 0],'LineWidth',2,'LineStyle','-');
else
    % If we already drawn the image once, just update WhichPanel is needed
    switch  WhichPanel       
        case 'both'
            CData = get(image_handle, 'CData');
            CData(:, size(CData,2)/2+1:size(CData,2),:) = PostCutResized;
            set(image_handle, 'CData', CData);   
            set(navi_handle, 'Position',[fymin,fxmin,NaviRectSize(2),NaviRectSize(1)]);
        case 'left'
            set(navi_handle, 'Position',[fymin,fxmin,NaviRectSize(2),NaviRectSize(1)]);
        case 'right'
            CData = get(image_handle, 'CData');
            CData(:, size(CData,2)/2+1:size(CData,2),:) = PostCutResized;
            set(image_handle, 'CData', CData);   
    end
end

%assignin('base','CData', get(image_handle, 'CData')); % Debug to see drawn matrix

end

function Res = detectPxPerPt
    %% Sets the units of your root object (screen) to pixels
    set(0,'units','pixels');
    %Obtains this pixel information
    Pix_SS = get(0,'screensize');
    %Sets the units of your root object (screen) to inches
    set(0,'units','inches');
    %Obtains this inch information
    Inch_SS = get(0,'screensize');
    %Calculates the resolution (pixels per inch)
    Res = Pix_SS./Inch_SS;
    Res = Res(3);
    % Convert resolution to px per pt (1 Point is defined as 1/72" inches)
    Res = Res/72;
end

function [ShapeCData, HotSpot] = getPointerCrosshair
    %% Custom mouse crosshair pointer sensitive at cross intersection point 
    ShapeCData = zeros(32,32);
    ShapeCData(:,:) = NaN;
    ShapeCData(15:17,:) = 1;
    ShapeCData(:, 15:17) = 1;
    HotSpot = [16,16];
end