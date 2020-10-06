% (C) Copyright 2020 Remi Gau

function [data, cfg] = prfMotion(cfg)
    % retinotopicMapping(cfg)
    %
    % Cyclic presentation with a rotating and/or expanding aperture.
    % Behind the aperture a background is displayed as a movie.
    
    % current: structure to keep track of which frame, refreshcycle, time, angle...
    % ring: structure to keep of several information about the annulus size
    
    cfg = userInputs(cfg);
    [cfg] = createFilename(cfg);
    
    % Prepare for the output logfiles with all
    logFile.extraColumns = cfg.extraColumns;
    logFile = saveEventsFile('open', cfg, logFile);

    %% Initialize
    data = [];
    frameTimes = [];  % To collect info about the frames
    
    % current stimulus Frame
    thisEvent.frame = 1;
    % current video Refresh
    thisEvent.refresh = 0;
    % current Angle of wedge
    thisEvent.angle = 0;
    thisEvent.time = 0;
    thisEvent.dotCenterXPosPix = 0;
    thisEvent.fileID = logFile.fileID;
    thisEvent.extraColumns = logFile.extraColumns;
    
    % current inner radius of ring
    cfg.ring.ringWidthVA = cfg.aperture.width;
    
    target.wasTarget = false;
    target.trial_type = 'target';
    target.fileID = logFile.fileID;
    target.extraColumns = logFile.extraColumns;
    target.target_width = cfg.target.size;
    

    %% Start
    try
        
        %% Initialize PTB
        [cfg] = initPTB(cfg);
        
        [cfg, target] = postInitializationSetup(cfg, target);
        
            % targetsTimings is a vector that says when (in seconds from the start of the
    % experiment) a target should be presented.
    targetsTimings = createTargetsTiming(cfg);
        
        cfg = dotTexture('init', cfg);
        
        thisEvent.speedPix = cfg.dot.speedPixPerFrame;
        thisEvent.direction = 0;
        
        dots = initDots(cfg, thisEvent);
        
        % Create aperture texture
        cfg = apertureTexture('init', cfg);
        
        % prepare the KbQueue to collect responses
        getResponse('init', cfg.keyboard.responseBox, cfg);
        
        [el] = eyeTracker('Calibration', cfg); %#ok<*NASGU>
        
        disp(cfg);
        
        standByScreen(cfg);
        
        %% Wait for start of experiment
        waitForTrigger(cfg);
        
        eyeTracker('StartRecording', cfg);
        getResponse('start', cfg.keyboard.responseBox);
        
        %% Start cycling the stimulus
        rft = Screen('Flip', cfg.screen.win);
        cfg.experimentStart = rft;
        
        %% Loop until the end of last cycle
        frameCounter = 0;
        while frameCounter < cfg.cyclingEnd
            
            checkAbort(cfg);
            
            dots.direction = dots.direction + cfg.dot.rotationStepDegPerFrame;
            
            directionAllDots = setDotDirection(dots.positions, cfg, dots, dots.isSignal);
            [horVector, vertVector] = decomposeMotion(directionAllDots);
            dots.speeds = [horVector, vertVector] * dots.speedPixPerFrame;
            
            [dots] = updateDots(dots, cfg);
            
            thisEvent.dot.positions = (dots.positions - cfg.dot.matrixWidth / 2)';
            
            dotTexture('make', cfg, thisEvent);
            
            [cfg, thisEvent] = apertureTexture('make', cfg, thisEvent);
            
            %% Draw stimulus
            % we draw the background stimulus in full and overlay an aperture on top of it
            
            % Display background
            dotTexture('draw', cfg, thisEvent);
            
            % Draw aperture
            apertureTexture('draw', cfg);
            
            drawFixation(cfg);
            
            %% Draw target
            thisEvent.time = GetSecs - cfg.experimentStart;
            [target] = drawTarget(target, targetsTimings, thisEvent, cfg);
            
            %% Flip current frame
            rft = Screen('Flip', cfg.screen.win, rft + cfg.screen.ifi);
            
            if rem(frameCounter, round(cfg.screen.monitorRefresh)) == 0
                
                thisEvent.onset = rft - cfg.experimentStart;
                thisEvent.duration = 0;
                thisEvent.trial_type = 'dot_motion';
                thisEvent.keyName = 'n/a';
                thisEvent.dotDirection = dots.direction;
                
                saveEventsFile('save', cfg, thisEvent);
                
            end
            
            
            %% Collect and save target info
            if target.isOnset
                target.onset = rft - cfg.experimentStart;
            elseif target.isOffset
                target.duration = (rft - cfg.experimentStart) - target.onset;
                target.keyName = 'n/a';
                saveEventsFile('save', cfg, target);
            end
            
            collectAndSaveResponses(cfg, logFile, cfg.experimentStart);
            
            frameCounter = frameCounter + 1;
            
        end
        
        %% End the experiment
        cfg = getExperimentEnd(cfg);
        
        getResponse('stop', cfg.keyboard.responseBox);
        getResponse('release', cfg.keyboard.responseBox);
        
        saveEventsFile('close', cfg, logFile);
        
        eyeTracker('StopRecordings', cfg);
        eyeTracker('Shutdown', cfg);
        
        %       data = feedbackScreen(cfg, expParameters);
        
        WaitSecs(1);
        
        createBoldJson(cfg, cfg);
        
        output = bids.util.tsvread( ...
            fullfile(cfg.dir.outputSubject, cfg.fileName.modality, ...
            cfg.fileName.events));
        
        disp(output);
        
        waitFor(4);
        
        %% Farewell screen
        farewellScreen(cfg);
        
        cleanUp;
        
    catch
        cleanUp;
        psychrethrow(psychlasterror);
    end
    
end

function varargout = postInitializationSetup(varargin)
    % varargout = postInitializatinSetup(varargin)
    %
    % generic function to finalize some set up after psychtoolbox has been
    % initialized
    
    [cfg, target] = deal(varargin{:});
    
    nbSecPerDeg = 1 / cfg.dot.rotationStepDegPerSec;
    nbSecPerCycle = 360 * nbSecPerDeg;
    cfg.cyclingEnd = nbSecPerCycle * cfg.cyclesPerExpmt * cfg.screen.monitorRefresh;
    
    cfg.volsPerCycle = nbSecPerCycle / cfg.mri.repetitionTime;
    
    cfg.dot.rotationStepDegPerFrame = cfg.dot.rotationStepDegPerSec / ...
        cfg.screen.monitorRefresh;
    
    % apply pixels per degree conversion
    target = degToPix('target_width', target, cfg);
    
    cfg.stimRect = [0 0 cfg.stimWidth cfg.stimWidth];
    
    % get the details about the destination rectangle where we want to draw the
    % stimulus
    cfg.destinationRect = cfg.stimRect;
    if isfield(cfg, 'stimDestWidth') && ~isempty(cfg.stimDestWidth)
        cfg.destinationRect = [0 0 cfg.stimDestWidth cfg.stimDestWidth];
        cfg.scalingFactor = cfg.destinationRect(3) / cfg.stimRect(3);
    end
    
    cfg.dot = degToPix('size', cfg.dot, cfg);
    cfg.dot = degToPix('speed', cfg.dot, cfg);
    
    cfg.dot.speedPixPerFrame = cfg.dot.speedPix / cfg.screen.monitorRefresh;
    
    % dots are displayed on a square
    cfg.dot.matrixWidth = cfg.destinationRect(3);
    cfg.dot.number = round(cfg.dot.density * ...
        (cfg.dot.matrixWidth / cfg.screen.ppd)^2);
    
    varargout = {cfg, target};
    
end
