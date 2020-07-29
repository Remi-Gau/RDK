function [apertureTexture, current] = getApertureCfg(cfg, current, apertureTexture, matrixSize, rect)

    style = cfg.aperture.style;

    cycleDuration = cfg.aperture.cycleDuration;

    current.appertureAngle = 90;

    switch style

        case 'none'

            Screen('FillOval', apertureTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(matrixSize, 1, 2)], rect(3) / 2, rect(4) / 2));

        case 'wedge'

            current.angle = 90 - cfg.aperture.width / 2;

            % Update angle for rotation of background and for apperture for wedge
            switch cfg.aperture.direction
                case '+'
                    current.angle = current.angle + (current.time / cycleDuration) * 360;
                case '-'
                    current.angle = current.angle - (current.time / cycleDuration) * 360;
            end

            Screen('FillArc', apertureTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(matrixSize, 1, 2)], rect(3) / 2, rect(4) / 2), ...
                current.angle, cfg.aperture.width);

        case 'bar'

            current.position = cfg.aperture.barPositions(current.volume);

            current.apperture_angle = cfg.aperture.direction(current.condition);

            % We let the stimulus through
            Screen('FillOval', apertureTexture, [0 0 0 0], ...
                CenterRect([0 0 repmat(matrixSize, 1, 2)], rect));

            % Then we add the position of the bar aperture
            Screen('FillRect', apertureTexture, cfg.color.gray, ...
                [0 0 current.position - cfg.aperture.barWidthPix / 2 rect(4)]);

            Screen('FillRect', apertureTexture, cfg.color.gray, ...
                [current.position + cfg.aperture.barWidthPix / 2 0 rect(3) rect(4)]);

        case 'ring'

            current = eccenLogSpeed(cfg, current);

            Screen('FillOval', apertureTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(current.ring.outerScalePix, 1, 2)], ...
                rect(3) / 2, rect(4) / 2));

            Screen('FillOval', apertureTexture, [repmat(cfg.color.gray, [1, 3]) 255], ...
                CenterRectOnPoint([0 0 repmat(current.ring.innerScalePix, 1, 2)], ...
                rect(3) / 2, rect(4) / 2));

    end

end
