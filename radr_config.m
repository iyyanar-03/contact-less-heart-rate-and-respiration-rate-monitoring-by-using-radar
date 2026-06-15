clc; clear;

% ===================== USER SETTINGS =====================
CLI_COM  = "COM11";
DATA_COM = "COM10";
CFG_FILE = "C:\Users\hp\OneDrive\Desktop\profile_2d.cfg";
DATA_BAUD_CANDIDATES = [921600, 115200, 1250000];
% ========================================================

disp("Available serial ports:");
disp(serialportlist("available"));

% Clean stale objects
try
    old = serialportfind;
    if ~isempty(old), clear old; end
catch
end

% Open CLI
cliPort = serialport(CLI_COM, 115200, "Timeout", 0.25);
configureTerminator(cliPort, "LF");
flush(cliPort);

% Open DATA initially at first candidate
dataBaud = DATA_BAUD_CANDIDATES(1);
dataPort = serialport(DATA_COM, dataBaud, "Timeout", 0.25);
flush(dataPort);

cleanupObj = onCleanup(@()cleanupPorts(cliPort, dataPort)); %#ok<NASGU>

fprintf("CLI=%s @115200, DATA=%s @%d\n", CLI_COM, DATA_COM, dataBaud);

% Hard reset from script (ignore missing response)
sendCli(cliPort, "sensorStop", false);
pause(0.2);
sendCli(cliPort, "flushCfg", false);
pause(0.2);

% Read cfg and strip control commands
cmds = readCfgLines(CFG_FILE);
cmds = stripControlCmds(cmds);

% Send cfg
for i = 1:numel(cmds)
    sendCli(cliPort, cmds(i), true);
    pause(0.03);
end

% Start once
sendCli(cliPort, "sensorStart", true);
disp("Started.");

% Probe data baud if needed
if ~hasIncomingBytes(dataPort, 3.0)
    disp("No bytes at initial DATA baud. Probing other baud rates...");
    delete(dataPort);
    found = false;
    for b = DATA_BAUD_CANDIDATES
        dataPort = serialport(DATA_COM, b, "Timeout", 0.25);
        flush(dataPort);
        fprintf("Trying DATA baud %d...\n", b);
        if hasIncomingBytes(dataPort, 2.5)
            dataBaud = b;
            found = true;
            fprintf("Detected DATA baud: %d\n", dataBaud);
            break;
        end
        delete(dataPort);
    end
    if ~found
        error("No data on %s at tested baud rates. Likely cfg/firmware mismatch or wrong DATA COM.", DATA_COM);
    end
end

disp("Reading mmWave packets... Ctrl+C to stop.");

% Packet read loop
MAGIC = uint8([2 1 4 3 6 5 8 7]);
buf = zeros(0,1,"uint8");

pktCount = 0;

while true
    n = dataPort.NumBytesAvailable;
    if n > 0
        chunk = read(dataPort, n, "uint8");
        buf = [buf; chunk(:)]; %#ok<AGROW>   % force column vector

    else
        pause(0.01);
        continue;
    end

    while true
        idx = strfind(reshape(buf,1,[]), reshape(MAGIC,1,[]));

        if isempty(idx)
            if numel(buf) > 64, buf = buf(end-63:end); end
            break;
        end

        s = idx(1);
        if s > 1, buf = buf(s:end); end
        if numel(buf) < 40, break; end

        totalLen = double(typecast(uint8(buf(13:16)), "uint32"));
        if totalLen < 40 || totalLen > 65535
            buf = buf(2:end,1);
            continue;
        end
        if numel(buf) < totalLen, break; end

        pkt = buf(1:totalLen);
        buf = buf(totalLen+1:end);

        frameNum = typecast(uint8(pkt(21:24)), "uint32");
        numTLVs  = typecast(uint8(pkt(33:36)), "uint32");
        pktCount = pktCount + 1;

        fprintf("Packet %d | Frame %u | Len %u | TLVs %u\n", pktCount, frameNum, totalLen, numTLVs);
    end
end

% ==================== FUNCTIONS ====================

function ok = sendCli(cli, cmd, expectReply)
    cmd = string(strtrim(cmd));
    if strlength(cmd)==0
        ok = true;
        return;
    end

    fprintf("CLI >> %s\n", char(cmd));
    flush(cli);
    writeline(cli, char(cmd));

    txt = string(strtrim(readCliText(cli, 0.8)));
             % char row vector
    txtStr = string(strtrim(txt));            % scalar string
    if strlength(txtStr) > 0
        pretty = replace(txtStr, newline, " | ");
        fprintf("CLI << %s\n", char(pretty)); % one line, not char-by-char
    end

    low = lower(txtStr);
    hasDone  = any(contains(low, "done"));
    hasError = any(contains(low, "error"));
    hasEcho  = any(contains(low, lower(cmd)));
    hasText  = strlength(txtStr) > 0;

    if hasError
        error("CLI error for '%s': %s", cmd, txtStr);
    end

    if expectReply && ~(hasDone || hasEcho || hasText)
        warning("No clear reply for '%s' (continuing).", cmd);
    end

    ok = true;
end

function txt = readCliText(cli, sec)
    t0 = tic;
    raw = zeros(0,1,"uint8");   % column buffer

    while toc(t0) < sec
        n = cli.NumBytesAvailable;
        if n > 0
            b = read(cli, n, "uint8");
            raw = [raw; b(:)]; %#ok<AGROW>   % force column
            pause(0.02);
        else
            pause(0.01);
        end
    end

    if isempty(raw)
        txt = "";
    else
        txt = string(char(raw.'));  % convert column bytes -> row text
    end
end


function tf = hasIncomingBytes(sp, sec)
    t0 = tic;
    tf = false;
    while toc(t0) < sec
        if sp.NumBytesAvailable > 0
            tf = true;
            return;
        end
        pause(0.02);
    end
end

function lines = readCfgLines(path)
    if ~isfile(path)
        error("CFG file not found: %s", path);
    end
    txt = fileread(path);
    raw = regexp(txt, '\r\n|\n|\r', 'split');
    lines = strings(0,1);
    for i = 1:numel(raw)
        t = strtrim(string(raw{i}));
        if strlength(t)==0 || startsWith(t,"%") || startsWith(t,"#")
            continue;
        end
        lines(end+1,1) = t; %#ok<AGROW>
    end
end

function out = stripControlCmds(in)
    out = strings(0,1);
    for i = 1:numel(in)
        c = lower(strtrim(in(i)));
        if startsWith(c,"sensorstart") || startsWith(c,"sensorstop") || startsWith(c,"flushcfg")
            continue;
        end
        out(end+1,1) = strtrim(in(i)); %#ok<AGROW>
    end
end

function cleanupPorts(cli, data)
    try, writeline(cli, "sensorStop"); catch, end
    try, flush(cli); catch, end
    try, flush(data); catch, end
    try, delete(cli); catch, end
    try, delete(data); catch, end
    disp("Ports closed.");
end
