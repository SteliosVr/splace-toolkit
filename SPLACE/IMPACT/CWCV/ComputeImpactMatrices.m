%{
 Copyright 2013 KIOS Research Center for Intelligent Systems and Networks, University of Cyprus (www.kios.org.cy)

 Licensed under the EUPL, Version 1.1 or � as soon they will be approved by the European Commission - subsequent versions of the EUPL (the "Licence");
 You may not use this work except in compliance with the Licence.
 You may obtain a copy of the Licence at:

 http://ec.europa.eu/idabc/eupl

 Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "AS IS" basis,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the Licence for the specific language governing permissions and limitations under the Licence.
%}

function ComputeImpactMatrices(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isstruct(varargin{1}) 
        file0=varargin{1}.file0;
        IM{1}.SensorThreshold=varargin{1}.SensorThreshold1;
        load([pwd,'\RESULTS\','pathname.File'],'pathname','-mat');
    else
        file0=varargin{1};
        %contaminanted water consumption volume
        IM{1}.SensorThreshold=0.3; %mg/L 
        pathname=[pwd,'\RESULTS\'];
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load([pathname,file0,'.0'],'-mat')
    load([pathname,file0,'.c0'],'-mat')
    load([pathname,'Simulate.Method'],'SimulateMethod','-mat');

    sizeflowscenarios=size(P.ScenariosFlowIndex,1);
    sizecontscenarios=size(P.ScenariosContamIndex,1);
    
    if strcmpi(SimulateMethod,'grid')
        totalscenarios=sizeflowscenarios*sizecontscenarios;
    elseif strcmpi(SimulateMethod,'random')
        totalscenarios=P.newTotalofScenarios;
    end
    disp('Compute Impact Matrix')
    Dt=double(B.TimeHydraulicStep)/60; % time step in minutes
    T=inf*ones(sizeflowscenarios*sizecontscenarios,B.CountNodes);
    W{1}=inf*ones(totalscenarios,B.CountNodes);
    %W{2}=inf*ones(sizeflowscenarios*sizecontscenarios,B.CountNodes);
    for i=1:length(D)
        demand{i}=zeros(size(D{1}.Demand,1),size(D{1}.Demand,2));
        demand{i}(:,B.NodeJunctionIndex)=D{i}.Demand(:,B.NodeJunctionIndex);
        demand{i}(find(demand{i}<0))=0;
    end
    
    l=0;pp=1;
    for i=1:t0
        if exist([pathname,file0,'.c',num2str(i)])==2
            try
                load([pathname,file0,'.c',num2str(i)],'-mat')
            catch err
                break
            end
            
            for k=1:size(C,2)
                c=C{k}.Quality;             
                l=l+1;
                %Contaminated Water Consumption Volume
                c1=c;
                c1(find(c1<=IM{1}.SensorThreshold))=0;
                c1(find(c1>IM{1}.SensorThreshold))=1;
                detectionNodes=find(sum(c1));
                cwv=c1.*Dt.*demand{d(k)}; %D{d(k)}.Demand.*Dt;
                for j=detectionNodes
                    [a tmp]=max(c1(:,j));
                    W{1}(l,j)=sum(sum(cwv(1:tmp,1:B.CountNodes)));
                end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if isstruct(varargin{1}) 
                    if mod(pp,100)==1
                        nload=pp/(totalscenarios); 
                        varargin{1}.color=char('red');
                        progressbar(varargin{1},nload)
                    end
                    pp=pp+1;
                end 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
                try
                    W{1}(l,find(W{1}(l,:)==inf))=sum(sum(cwv(1:size(cwv,1),1:B.CountNodes))); 
                catch err
                end
            end
            clear C;
            W{1}(:,find(P.SensingNodeIndices==0))=0;
            save([pathname,file0,'.w'],'W', 'IM', '-mat');
        end
    end
end