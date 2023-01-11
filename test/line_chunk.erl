%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright © 2022-2023 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(line_chunk).

-include_lib("eunit/include/eunit.hrl").

decode_line_chunk_test() ->
    %% Taken from `rabbit_amqqueue'.
    Module = rabbit_amqqueue,
    Chunk = <<0,0,0,0,0,0,0,0,0,0,4,187,0,0,3,242,0,0,0,0,9,122,9,
              123,9,124,9,128,9,132,9,130,9,140,9,141,9,142,9,144,
              9,145,9,147,9,152,9,153,9,156,9,158,9,159,9,160,9,
              161,9,165,9,171,9,176,9,177,9,189,9,190,9,191,9,198,
              9,199,9,200,9,207,9,208,9,216,9,217,9,227,9,228,9,
              229,9,230,9,237,9,238,9,246,9,247,9,253,9,254,9,255,
              41,0,41,17,41,35,41,37,41,38,41,39,41,41,41,50,41,
              55,41,58,41,59,41,63,41,61,41,69,41,71,41,73,41,77,
              41,78,41,86,41,94,41,95,41,101,41,102,41,103,41,104,
              41,110,41,111,41,112,41,113,41,115,41,120,41,121,41,
              122,41,124,41,127,41,128,41,129,41,131,41,134,41,
              135,41,136,41,152,41,153,41,154,41,155,41,156,41,
              157,41,158,41,159,41,180,41,181,41,185,41,190,41,
              191,41,203,41,204,41,206,41,207,41,208,41,210,41,
              218,41,219,41,220,41,222,41,223,41,224,41,227,41,
              228,41,239,41,241,41,243,41,247,41,248,41,252,41,
              253,73,3,73,8,73,9,73,10,73,15,73,16,73,18,73,19,73,
              23,73,24,73,28,73,29,73,38,73,39,73,43,73,45,73,49,
              73,65,73,66,73,67,73,68,73,69,73,70,73,71,73,76,73,
              77,73,79,73,81,73,87,73,88,73,89,73,98,73,103,73,
              104,73,108,73,112,73,114,73,116,73,117,73,122,73,
              127,73,128,73,133,73,134,73,135,73,140,73,145,73,
              150,73,153,73,160,73,163,73,164,73,171,73,172,73,
              176,73,180,73,187,73,192,73,201,73,203,73,205,73,
              206,73,208,73,209,73,210,73,215,73,216,73,217,73,
              221,73,222,73,223,73,224,73,227,73,231,73,238,73,
              243,73,246,73,249,73,250,73,252,73,253,73,255,105,7,
              105,8,105,10,105,19,105,41,105,21,105,22,105,23,105,
              26,105,28,105,30,105,29,105,31,105,36,105,37,105,33,
              105,34,105,46,105,45,105,11,105,50,105,51,105,53,
              105,56,105,54,105,58,105,60,105,59,105,64,105,65,
              105,67,105,68,105,75,105,82,105,85,105,86,105,90,
              105,93,105,96,105,102,105,115,105,119,105,128,105,
              129,105,130,105,131,105,132,105,136,105,138,105,144,
              105,145,105,149,105,150,105,156,105,160,105,161,105,
              166,105,173,105,178,105,179,105,180,105,181,105,187,
              105,195,105,192,105,210,105,208,105,200,105,198,105,
              205,105,203,105,216,105,213,105,223,105,224,105,225,
              105,226,105,227,105,228,105,229,105,230,105,235,105,
              237,105,244,105,250,105,245,105,255,137,3,137,4,137,
              5,137,7,137,6,137,9,137,10,137,12,137,13,137,15,137,
              26,137,29,137,49,137,53,137,54,137,56,137,63,137,69,
              137,70,137,76,137,82,137,83,137,85,137,89,137,91,
              137,95,137,96,137,97,137,101,137,102,137,106,137,
              107,137,113,137,119,137,124,137,125,137,131,137,137,
              137,138,137,147,137,148,137,150,137,152,137,154,137,
              155,137,166,137,175,137,173,137,167,137,169,137,171,
              137,181,137,186,137,187,137,194,137,202,137,203,137,
              210,137,218,137,219,137,226,137,233,137,234,137,242,
              137,243,137,245,137,250,137,252,169,2,169,3,169,5,
              169,10,169,12,169,19,169,22,169,23,169,27,169,28,
              169,30,169,31,169,32,169,33,169,39,169,40,169,44,
              169,45,169,47,169,48,169,49,169,50,169,56,169,57,
              169,61,169,62,169,64,169,65,169,66,169,71,169,73,
              169,74,169,77,169,78,169,82,169,84,169,92,169,95,
              169,99,169,106,169,100,169,111,169,107,169,114,169,
              117,169,123,169,127,169,131,169,133,169,132,169,141,
              169,142,169,143,169,147,169,148,169,153,169,154,169,
              159,169,160,169,165,169,166,169,171,169,173,169,181,
              169,182,169,189,169,190,169,198,169,199,169,210,169,
              211,169,223,169,224,169,230,169,231,169,237,169,238,
              169,244,169,245,169,248,169,251,169,252,201,4,201,5,
              201,13,201,14,201,15,201,16,201,18,201,19,201,20,
              201,21,201,23,201,24,201,28,201,44,201,45,201,47,
              201,51,201,53,201,60,201,65,201,66,201,68,201,72,
              201,74,201,83,201,84,201,87,201,88,201,89,201,93,
              201,90,201,96,201,103,201,105,201,110,201,111,201,
              132,201,134,201,136,201,139,201,141,201,162,201,163,
              201,150,201,151,201,172,201,173,201,177,201,183,201,
              184,201,186,201,187,201,189,201,190,201,194,201,195,
              201,196,201,201,201,202,201,203,201,205,201,207,201,
              206,201,209,201,210,201,211,201,213,201,214,201,216,
              201,217,201,218,201,220,201,225,201,233,201,236,201,
              234,201,238,201,244,201,239,201,247,201,249,201,250,
              201,252,201,253,201,255,233,0,233,8,233,11,233,13,
              233,17,233,18,233,25,233,26,233,27,233,29,233,30,
              233,31,233,42,233,48,233,49,233,51,233,50,233,54,
              233,55,233,56,233,59,233,60,233,64,233,61,233,66,
              233,70,233,74,233,75,233,80,233,85,233,86,233,93,
              233,94,233,98,233,99,233,100,233,106,233,107,233,
              108,233,110,233,128,233,129,233,132,233,133,233,135,
              233,136,233,139,233,140,233,143,233,144,233,150,233,
              157,233,158,233,166,233,171,233,167,233,174,233,175,
              233,179,233,180,233,185,233,198,233,199,233,200,233,
              205,233,206,233,207,233,216,233,217,233,224,233,225,
              233,235,233,239,233,242,233,253,25,8,3,25,8,4,25,8,
              9,25,8,10,25,8,12,25,8,13,25,8,15,25,8,16,25,8,20,
              25,8,23,25,8,26,25,8,27,25,8,35,25,8,36,25,8,39,25,
              8,41,25,8,44,25,8,48,25,8,50,25,8,51,25,8,52,25,8,
              53,25,8,54,25,8,57,25,8,62,25,8,65,25,8,66,25,8,74,
              25,8,75,25,8,95,25,8,96,25,8,111,25,8,113,25,8,116,
              25,8,118,25,8,125,25,8,129,25,8,128,25,8,143,25,8,
              147,25,8,150,25,8,162,25,8,163,25,8,166,25,8,167,25,
              8,154,25,8,172,25,8,174,25,8,175,25,8,176,25,8,177,
              25,8,178,25,8,191,25,8,192,25,8,196,25,8,197,25,8,
              201,25,8,202,25,8,206,25,8,207,25,8,212,25,8,213,25,
              8,214,25,8,216,25,8,221,25,8,222,25,8,223,25,8,225,
              25,8,229,25,8,230,25,8,235,25,8,240,25,8,241,25,8,
              243,25,8,246,25,8,247,25,8,250,25,8,253,25,8,254,25,
              9,2,25,9,3,25,9,11,25,9,12,25,9,13,25,9,14,25,9,28,
              25,9,29,25,9,33,25,9,35,25,9,44,25,9,45,25,9,46,25,
              9,48,25,9,50,25,9,51,25,9,52,25,9,55,25,9,56,25,9,
              73,25,9,74,25,9,75,25,9,77,25,9,78,25,9,79,25,9,89,
              25,9,90,25,9,94,25,9,95,25,9,105,25,9,106,25,9,107,
              25,9,109,25,9,124,25,9,125,25,9,138,25,9,139,25,9,
              149,25,9,154,25,9,157,25,9,170,25,9,174,25,9,175,25,
              9,178,25,9,179,25,9,186,25,9,188,25,9,191,25,9,194,
              25,9,197,25,9,202,25,9,207,25,9,208,25,9,209,25,9,
              211,25,9,214,25,9,215,25,9,216,25,9,218,25,9,221,25,
              9,222,25,9,223,25,9,225,25,9,228,25,9,229,25,9,230,
              25,9,232,25,9,235,25,9,236,25,9,237,25,9,239,25,9,
              242,25,9,243,25,9,244,25,9,246,25,9,140,25,9,141,25,
              9,126,25,9,130,25,9,128,25,9,127,25,9,110,25,9,111,
              25,9,112,25,9,113,25,9,115,25,9,96,25,9,97,25,9,98,
              25,9,99,25,9,100,25,9,101,25,9,65,25,9,66,25,9,67,
              25,9,68,25,9,69,25,9,57,25,9,58,25,9,62,25,9,59,25,
              9,60,25,9,61,25,9,4,25,9,6,25,9,5,25,9,7,25,8,130,
              25,8,132,25,8,131,25,8,134,25,8,135,25,8,133,25,8,
              97,25,8,98,25,8,99,25,8,76,25,8,77,25,8,78,25,8,80,
              25,8,82,25,8,83,25,8,85,25,8,86,25,8,87,25,8,88,25,
              8,70,25,8,67,25,8,31,25,8,28,233,186,233,187,233,
              109,233,68,233,67,233,63,233,52,233,12,233,1,201,
              248,201,240,201,235,201,120,201,122,201,112,201,114,
              201,117,201,115,201,91,201,92,201,26,201,25,201,6,
              201,9,201,7,201,0,201,1,169,253,169,254,169,232,169,
              233,169,234,169,235,169,225,169,226,169,227,169,220,
              169,213,169,215,169,217,169,200,169,201,169,203,169,
              204,169,205,169,206,169,191,169,192,169,193,169,194,
              169,183,169,184,169,185,169,186,169,174,169,175,169,
              176,169,177,169,167,169,168,169,161,169,162,169,155,
              169,156,169,149,169,150,169,134,169,136,169,135,169,
              129,169,128,169,108,169,103,169,79,169,80,169,75,
              169,59,169,58,169,42,169,41,169,25,169,24,137,51,
              137,50,137,47,137,44,137,43,137,42,137,41,137,40,
              137,39,137,38,137,34,137,33,137,32,137,31,137,30,
              137,16,137,18,137,23,137,20,137,1,105,167,105,104,
              105,103,105,117,105,116,105,69,105,70,105,71,105,72,
              105,61,105,55,105,12,105,15,105,16,73,211,73,212,73,
              213,73,214,73,174,73,173,73,123,73,124,73,118,73,
              106,73,105,73,50,73,51,73,53,73,54,73,55,73,30,73,
              31,73,26,73,25,41,254,41,255,73,0,41,250,41,249,41,
              197,41,198,41,192,41,193,41,183,41,182,41,160,41,
              161,41,163,41,165,41,171,41,167,41,168,41,137,41,
              138,41,148,41,140,41,145,41,141,41,142,41,143,41,
              144,41,105,41,106,41,96,41,97,41,98,41,82,41,79,41,
              90,41,87,41,1,9,248,9,249,9,250,9,242,9,239,9,231,9,
              218,9,220,9,219,9,221,9,222,9,223,9,212,9,209,9,201,
              9,203,9,204,9,202,9,192,9,194,9,195,9,193,9,183,9,
              185,9,178,9,180,9,173,9,170,9,149,9,150>>,
    ?assertMatch(
       {lines,
        1011,
        [{line, 0, _} | _],
        1,
        ["rabbit_amqqueue.erl"],
        _},
       khepri_fun:decode_line_chunk(Module, Chunk)).
