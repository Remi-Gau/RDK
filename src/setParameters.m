function [cfg] = setParameters(cfg)

    cfg.verbose = false;

    if cfg.debug.do
        cfg.debug.transpWin = true;
        cfg.debug.smallWin = false;
    else
        cfg.debug.transpWin = false;
        cfg.debug.smallWin = false;
    end

    cfg.dir.output = fullfile(fileparts(mfilename('fullpath')), 'output');

    %% Splash screens
    cfg.welcome = 'Please fixate the black dot at all times!';
    cfg.task.instruction = 'Press the button everytime it changes color!';

    %% Feedback screens
    cfg.hit = 'You responded %i / %i times when there was a target.';
    cfg.miss = 'You did not respond %i / %i times when there was a target.';
    cfg.fa = 'You responded %i times when there was no target.';
    cfg.respWin = 2; % duration of the response window

    %% Dots details
    % dots per degree^2
    cfg.dot.density = .15;
    % max dot speed (deg/sec)
    cfg.dot.speed = 15;
    % width of dot (deg)
    cfg.dot.width = .25;
    % fraction of dots to kill each frame (limited lifetime)
    cfg.dot.fractionKill = 0.05;
    % Amount of coherence
    cfg.dot.coherence = 1;
    % starting motion direction: 0 gives right, 90 gives down, 180 gives left and 270 up.
    cfg.dot.angleMotion = 0;
    % speed rotation of motion direction in degrees per second
    cfg.dot.speedRotationMotion = 360 / 15;

    %% Aperture details

    switch  cfg.aperture.type

        case 'none'
            cfg.aperture.width = NaN;
            cfg.aperture.volsPerCycle = NaN;
            cfg.aperture.direction = NaN;

        case 'bar'
            % aperture motion direction
            cfg.aperture.direction = [90 45 0 135 270 225 180 315];
            cfg.aperture.volsPerCycle = 12;

        case 'ring'
            % aperture width in deg VA (bar or annulus)
            cfg.aperture.width = 2;
            cfg.aperture.volsPerCycle = 60;

        case 'wedge'
            % aperture width in deg (wedge)
            cfg.aperture.width = 60;
            cfg.aperture.volsPerCycle = 60;
    end

    cfg.cyclesPerExpmt = 3;
    cfg.volsPerCycle = cfg.aperture.volsPerCycle;
    cfg.aperture.framePerVolume = 3;

    %% Experiment parameters

    cfg.fixation.type = 'cross'; % dot bestFixation
    cfg.fixation.width = .15; % in degrees VA

    [cfg] = setMonitor(cfg);
    [cfg] = setMRI(cfg);
    [cfg] = setKeyboards(cfg);

    % Target parameters
    % Changing those parameters might affect participant's performance
    % Need to find a set of parameters that give 85-90% accuracy.

    % Probability of a target event
    cfg.target.probability = 0.1;
    % Duration of a target event in ms
    cfg.target.duration = 0.15;
    % diameter of target circle in degrees VA
    cfg.target.size = .15;
    % rgb color of the target
    cfg.target.color = [255 200 200];
    % is the fixation dot the only possible location of the target?
    % setting this to true might induce more saccade (not formally tested)
    cfg.target.central = true;

    cfg.fixation.size = .15; % in degrees VA

    %% Animation details
    % proportion of screeen height occupied by the RDK
    cfg.matrixSize = .99;
    % number of animation frames in loop
    cfg.nbFrames = 1600;
    % Show new dot-images at each waitframes'th monitor refresh
    cfg.waitFrames = 1;

    %% Eyetracker parameters
    cfg.eyeTracker.do = false;
    %     cfg.eyeTrackerParam.host = '10.41.111.213';  % SMI machine ip: '10.41.111.213'
    %     cfg.eyeTrackerParam.Port = 4444;
    %     cfg.eyeTrackerParam.Window = 1;

    %% Compute some more parameters

    % aperture details
    cfg.aperture.cycleDuration = cfg.mri.repetitionTime * ...
        cfg.aperture.volsPerCycle;

    switch cfg.aperture.type

        case 'ring'

            cfg.screen.FOV = computeFOV(cfg);

            % ring apertures
            % cs_func_fact is used to expand with log increasing speed so that ring is at
            % max_ecc at end of cycle
            cfg.ring.maxEcc = ...
                cfg.screen.FOV / 2 + cfg.aperture.width + log(cfg.screen.FOV / 2 + 1);
            cfg.ring.csFuncFact = ...
                1 / ((cfg.ring.maxEcc + exp(1)) * ...
                log(cfg.ring.maxEcc + exp(1)) - ...
                (cfg.ring.maxEcc + exp(1)));

    end

    %% DO NOT TOUCH

    cfg.audio.do = false;

    % % %         expParameters.extraColumns.wedge_angle = struct( ...
    % % %         'length', 1, ...
    % % %         'bids', struct( ...
    % % %         'LongName', 'angular width of the wedge', ...
    % % %         'Units', 'degrees'));

    cfg.extraColumns.x_target_pos = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'x position of the the target', ...
        'Units', 'degrees of visual angles'));

    cfg.extraColumns.y_target_pos = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'y position of the the target', ...
        'Units', 'degrees of visual angles'));

    cfg.extraColumns.target_width = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'diameter of the the target', ...
        'Units', 'degrees of visual angles'));

end

function [cfg] = setKeyboards(cfg)
    cfg.keyboard.escapeKey = 'ESCAPE';
    cfg.keyboard.responseKey = {'space'};
    cfg.keyboard.keyboard = [];
    cfg.keyboard.responseBox = [];

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.keyboard.keyboard = [];
        cfg.keyboard.responseBox = [];
    end
end

function [cfg] = setMRI(cfg)
    % letter sent by the trigger to sync stimulation and volume acquisition
    cfg.mri.triggerKey = 't';
    cfg.mri.triggerNb = 4;
    cfg.mri.triggerString = 'Waiting for the scanner';

    cfg.mri.repetitionTime = 1;

    cfg.bids.MRI.Instructions = '';
    cfg.bids.MRI.TaskDescription = [];

end

function [cfg] = setMonitor(cfg)

    % Monitor parameters for PTB
    cfg.color.white = [255 255 255];
    cfg.color.black = [0 0 0];
    cfg.color.red = [255 0 0];
    cfg.color.gray = mean([cfg.color.black; cfg.color.white]);
    cfg.color.background = [127 127 127];
    cfg.color.foreground = cfg.color.black;

    % Monitor parameters
    cfg.screen.monitorWidth = 42; % in cm
    cfg.screen.monitorDistance = 134; % distance from the screen in cm

    % Resolution [width height refresh_rate]
    cfg.screen.resolution = [800 600 60];

    cfg.text.color = cfg.color.black;
    cfg.text.font = 'Courier New';
    cfg.text.size = 18;
    cfg.text.style = 1;

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.screen.monitorWidth = 42; % in cm
        cfg.screen.monitorDistance = 134; % distance from the screen in cm
    end
end
