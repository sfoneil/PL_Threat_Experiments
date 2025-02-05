%% Example code demonstrating sending and receiving commands to interface with Pupil-Labs Pupil Capture app

clear

% Can do these next two lines dynamically or add to Environment Variables?
JARPATH = 'C:\toolbox\jeromq\target\jeromq-0.6.0-SNAPSHOT.jar';
javaclasspath(JARPATH)

import org.zeromq.*
ctx = ZContext();
%subscriber = ctx.createSocket(SocketType.SUB);

publisher = ctx.createSocket(SocketType.REQ); % Pub crashes. change below?
%publisher.bind('tcp://127.0.0.1:50020');
publisher.connect('tcp://127.0.0.1:50020');

%publisher.send('r')
%qq = publisher.recv();
publisher.send('R'); % Start recording
rtime = publisher.recv(); % == 'O' 'K'
publisher.send('t'); % Request time
firstTime = publisher.recv(); % Get time value

WaitSecs(10);
publisher.send('t'); % Request time
secondTime = publisher.recv(); % Get time value

% It will be split integers, subtract 48 or int8('0') from each??


% Get time span:
%str2num(char(secondTime')) - str2num(char(firstTime'));

% These are 5 s apart (ans = 5.0472)
% 50
% 48
% 50
% 50
% 46
% 57
% 48
% 57
% 56
% 54
% 49
% 
% 50
% 48
% 50
% 55
% 46
% 57
% 53
% 55
% 48
% 53
% 53

%publisher.unbind('tcp://127.0.0.1:50020');
publisher.disconnect('tcp://127.0.0.1:50020');