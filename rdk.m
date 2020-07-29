function rdk(cfg)
    
    if nargin < 1
        apertureType = 'wedge';
    end
    if nargin < 2
        direction = '-';
    end
    if nargin < 3
        emul = 1;
    end
    if nargin < 4
        debug = 1;
    end
    
    initEnv();
    
    %% Experiment parameters
    
    cfg.task.name = 'retinotopyPolar';
    
    cfg.aperture.type = apertureType;
    cfg.aperture.direction = direction;
    
    cfg.debug.do = debug;
    
    if ~emul
        cfg.testingDevice = 'mri';
    else
        cfg.testingDevice = 'pc';
    end
    
    cfg = setParameters(cfg);
    
    cfg = userInputs(cfg);
    cfg = createFilename(cfg);
    
    % Prepare for the output logfiles with all
    logFile.extraColumns = cfg.extraColumns;
    logFile = saveEventsFile('open', cfg, logFile);
    
    disp(cfg);
    
    %% Initialize variables
    
    target.wasTarget = false;
    target.trial_type = 'target';
    target.fileID = logFile.fileID;
    target.extraColumns = logFile.extraColumns;
    target.target_width = cfg.target.size;
    target.size = cfg.target.size;
    
    current.frame = 0;
    current.stim = 1;
    current.angleMotion = cfg.dot.angleMotion;
    
    %% Setup
    % TODO
    % Randomness
    %     setUpRand;
    
    % Event timings
    % Events is a vector that says when (in seconds from the start of the
    % experiment) a target should be presented.
    targetsTimings = createTargetsTiming(cfg);
    
    % put everything into a try / catch in case the poop hits the fan
    try
        
        %% Initialize PTB
        
        [cfg] = initPTB(cfg);
        
        cfg.framePerVolume = ceil(cfg.mri.repetitionTime / cfg.screen.ifi);
        
        % apply pixels per degree conversion
        target = degToPix('size', target, cfg);
        cfg.fixation = degToPix('size', cfg.fixation, cfg);
        
        %% Set general RDK and display details
        % diameter of circle covered by the RDK
        matrixSize = floor(cfg.screen.winRect(4) * cfg.matrixSize);
        
        % set center of the dot texture that will be created
        stimRect = [0 0 repmat(matrixSize, 1, 2)];
        [center(1, 1), center(1, 2)] = RectCenter(stimRect);
        
        % dot speed (pixels/frame) - pixel frame speed
        pixelPerFrame = cfg.dot.speed * cfg.screen.ppd * cfg.screen.ifi;
        
        % dot size (pixels)
        dotSize = cfg.dot.width * cfg.screen.ppd;
        
        % Number of dots : surface of the RDK disc * density of dots
        nDots = getNumberDots(cfg.dot.width, matrixSize,  cfg.dot.density, cfg.screen.ppd);
        
        % decide which dots are signal dots (1) and those are noise dots (0)
        dotNature = rand(nDots, 1) < cfg.dot.coherence;
        
        % speed rotation of motion direction in degrees per frame
        speedRotationMotion = cfg.dot.speedRotationMotion * cfg.screen.ifi;
        
        %% Aperture variables
        if strcmp (cfg.aperture.type, 'bar')
            barWidthPix = stimRect(3) / cfg.aperture.volsPerCycle;
            barPositions = [0:barWidthPix:stimRect(3) - barWidthPix] + ...
                (cfg.screen.winRect(3) / 2 - stimRect(3) / 2) + barWidthPix / 2; %#ok<NBRAK>
            
            cfg.aperture.barWidthPix = barWidthPix;
            cfg.aperture.barPositions = barPositions;
            
            % Width and position of bar in degrees of VA (needed for saving)
            cfg.aperture.barWidth = barWidthPix / cfg.screen.ppd;
            cfg.aperture.barPositions = (barPositions - cfg.screen.winRect(3) / 2) / cfg.screen.ppd;
            clear barWidthPix barPositions;
        end
        
        %% Initialize dots
        % Dot positions and speed matrix : colunm 1 to 5 gives respectively
        % x position, y position, x speed, y speed, and distance of the point the RDK center
        xy = zeros(nDots, 5);
        
        % fills a square with dots and we will later remove those outside of
        % the frame
        [X] = getX(nDots, matrixSize);
        [Y] = getY(nDots, matrixSize, X);
        
        xy(:, 1) = X;
        xy(:, 2) = Y;
        clear X Y;
        
        % decompose angle of start motion into horizontal and vertical vector
        [horVector, vertVector] = decompMotion(current.angleMotion);
        
        % Gives a pre determinded horizontal and vertical speed to the signal dots
        xy = getXYMotion(xy, dotNature, horVector, vertVector, pixelPerFrame);
        
        % Gives a random horizontal and vertical speed to the other ones
        xy(~dotNature, 3:4) = randn(sum(~dotNature), 2) * pixelPerFrame;
        
        % calculate distance from matrix center for each dot
        xy = getDistToCenter(xy);
        
        %% Initialize textures
        % Create dot texture
        dotTexture = Screen('MakeTexture', cfg.screen.win, cfg.color.gray(1) * ones(matrixSize));
        
        % Aperture texture
        apertureTexture = Screen('MakeTexture', cfg.screen.win, ...
            cfg.color.gray(1) * ones(cfg.screen.winRect([4 3])));
        
        % prepare the KbQueue to collect responses
        getResponse('init', cfg.keyboard.responseBox, cfg);
        
        %         [el] = eyeTracker('Calibration', cfg); %#ok<*NASGU>
        
        standByScreen(cfg);
        
        %% Wait for start of experiment
        waitForTrigger(cfg);
        
        
        
        %% Start
        getResponse('start', cfg.keyboard.responseBox);
        %         eyeTrack(cfg, 'start');
        
        % Do initial flip...
        vbl = Screen('Flip', cfg.screen.win);
        cfg.experimentStart = vbl;
        
        current.cycle = 1;
        current.frame = 1;
        current.volume = 1;
        current.condition = 1;
        
        for i = 1:cfg.nbFrames
            
            checkAbort(cfg);
            
            current.time = GetSecs -  cfg.experimentStart;
            
            current.frame = current.frame + 1;
            
            if current.frame > cfg.aperture.framePerVolume
                current.frame = 1;
                current.volume = current.volume + 1;
            end
            
            if current.volume > cfg.aperture.framePerVolume
                current.volume = 1;
                current.condition = current.condition + 1;
            end
            
            %% Remove dots that are too far out, kill dots, reseed dots,
            % Finds if there are dots to reposition because out of the RDK
            xy = dotsROut(xy, matrixSize);
            
            % Kill some dots and reseed them at random position
            xy = dotsReseed(nDots, cfg.dot.fractionKill, matrixSize, xy);
            
            % calculate distance from matrix center for each dot
            xy = getDistToCenter(xy);
            
            % find dots that are within the RDK area
            rIn = xy(:, 5) <= matrixSize / 2;
            
            % find the dots that do not overlap with fixation dot
            rFixation = xy(:, 5) > cfg.fixation.sizePix * 2;
            
            % only pass those that match all those conditions
            rIn = find(all([ ...
                rIn, ...
                rFixation], 2));
            
            % change of format for PTB
            xyMatrix = transpose(xy(rIn, 1:2)); %#ok<FNDSB>
            
            %% Create apperture texture for this frame
            Screen('Fillrect', apertureTexture, cfg.color.gray);
            
            [apertureTexture, current] = ...
                getApertureCfg(cfg, current, apertureTexture, matrixSize, cfg.screen.winRect);
            
            %% Actual PTB stuff
            % sanity check before drawin the dots in the texture
            if ~isempty(xyMatrix)
                Screen('FillRect', dotTexture, cfg.color.gray);
                Screen('DrawDots', dotTexture, xyMatrix, dotSize, cfg.color.white, center, 1);
            else
                warning('no dots to plot');
                break
            end
            
            % Draw dot texture, aperture texture, fixation gap around fixation
            % and fixation dot
            Screen('DrawTexture', cfg.screen.win, dotTexture, stimRect, CenterRect(stimRect, cfg.screen.winRect));
            
            Screen('DrawTexture', cfg.screen.win, apertureTexture, ...
                cfg.screen.winRect, cfg.screen.winRect, current.appertureAngle - 90);
            
            drawFixation(cfg);
            
            [target] = drawTarget(target, targetsTimings, current, current, cfg);
            
            %% Flip current frame
            vbl = Screen('Flip', cfg.screen.win, vbl + cfg.screen.ifi);
            
            %% Collect and save target info
            if target.isOnset
                target.onset = vbl - cfg.experimentStart;
            elseif target.isOffset
                target.duration = (vbl - cfg.experimentStart) - target.onset;
                saveEventsFile('save', cfg, target);
            end
            
            collectAndSaveResponses(cfg, logFile, cfg.experimentStart);
            
            %% Update everything
            
            % Move the dots
            xy(:, 1:2) = xy(:, 1:2) + xy(:, 3:4);
            
            % update motion direction
            current.angleMotion = current.angleMotion + speedRotationMotion;
            [horVector, vertVector] = decompMotion(current.angleMotion);
            
            % update dot matrix
            xy = getXYMotion(xy, dotNature, horVector, vertVector, pixelPerFrame);
            
            clear xyMatrix;
            
        end
        
        %% End the experiment
        drawFixation(cfg);
        endExpmt = Screen('Flip', cfg.screen.win);
        
        dispExpDur(endExpmt, cfg.experimentStart);
        
        getResponse('stop', cfg.keyboard.responseBox);
        getResponse('release', cfg.keyboard.responseBox);
        
        saveEventsFile('close', cfg, logFile);
        
        %         eyeTracker('StopRecordings', cfg);
        %         eyeTracker('Shutdown', cfg);
        %
        %       data = feedbackScreen(cfg, expParameters);
        
        WaitSecs(1);
        
        %% Save
        % TODO
        %         data = save2TSV(frameTimes, behavior, expParameters);
        
        
        matFile = fullfile( ...
            cfg.dir.output, ...
            strrep(cfg.fileName.events, 'tsv', 'mat'));
        if IsOctave
            save(matFile, '-mat7-binary');
        else
            save(matFile, '-v7.3');
        end
        
        output = bids.util.tsvread( ...
            fullfile(cfg.dir.outputSubject, cfg.fileName.modality, ...
            cfg.fileName.events));
        
        disp(output);
        
        WaitSecs(4);
        
        %% Farewell screen
        farewellScreen(cfg);
        
        cleanUp;
        
    catch
        cleanUp;
        psychrethrow(psychlasterror);
    end
    
end
