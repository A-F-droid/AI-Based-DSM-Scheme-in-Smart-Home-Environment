function gwoDatOutput = igwo(gaDat)

% ================== EXTRACT DATA ==================
lb = gaDat.FieldD(1,:);
ub = gaDat.FieldD(2,:);
dim = length(lb);

N = gaDat.NIND;
Max_iter = gaDat.MAXGEN;

fobj = str2func(gaDat.Objfun);

% Bounds matrix
lu = [lb; ub];

% ================== INITIALIZATION ==================
Positions = rand(N,dim).*(ub-lb)+lb;
Positions = boundConstraint(Positions, Positions, lu);

Alpha_pos=zeros(1,dim);
Alpha_score=inf;

Beta_pos=zeros(1,dim);
Beta_score=inf;

Delta_pos=zeros(1,dim);
Delta_score=inf;

Fit = zeros(N,1);

for i=1:N
    Fit(i) = fobj(Positions(i,:));
end

pBest = Positions;
pBestScore = Fit;

Convergence_curve=zeros(1,Max_iter);

% ================== MAIN LOOP ==================
for iter=1:Max_iter
    
    % --- Update Alpha, Beta, Delta ---
    for i=1:N
        fitness = Fit(i);
        
        if fitness < Alpha_score
            Alpha_score = fitness;
            Alpha_pos = Positions(i,:);
        elseif fitness < Beta_score
            Beta_score = fitness;
            Beta_pos = Positions(i,:);
        elseif fitness < Delta_score
            Delta_score = fitness;
            Delta_pos = Positions(i,:);
        end
    end
    
    a = 2 - iter*(2/Max_iter);
    
    % ================= GWO UPDATE =================
    X_GWO = zeros(N,dim);
    Fit_GWO = zeros(N,1);
    
    for i=1:N
        for j=1:dim
            
            r1=rand(); r2=rand();
            A1=2*a*r1-a; C1=2*r2;
            D_alpha=abs(C1*Alpha_pos(j)-Positions(i,j));
            X1=Alpha_pos(j)-A1*D_alpha;
            
            r1=rand(); r2=rand();
            A2=2*a*r1-a; C2=2*r2;
            D_beta=abs(C2*Beta_pos(j)-Positions(i,j));
            X2=Beta_pos(j)-A2*D_beta;
            
            r1=rand(); r2=rand();
            A3=2*a*r1-a; C3=2*r2;
            D_delta=abs(C3*Delta_pos(j)-Positions(i,j));
            X3=Delta_pos(j)-A3*D_delta;
            
            X_GWO(i,j) = (X1+X2+X3)/3;
        end
        
        X_GWO(i,:) = boundConstraint(X_GWO(i,:), Positions(i,:), lu);
        Fit_GWO(i) = fobj(X_GWO(i,:));
    end
    
    % ================= DLH UPDATE =================
    radius = pdist2(Positions, X_GWO, 'euclidean');
    dist_Position = squareform(pdist(Positions));
    
    X_DLH = zeros(N,dim);
    Fit_DLH = zeros(N,1);
    
    r1 = randperm(N,N);
    
    for t=1:N
        neighbor = (dist_Position(t,:) <= radius(t,t));
        Idx = find(neighbor == 1);
        
        if isempty(Idx)
            Idx = t;
        end
        
        randIdx = Idx(randi(length(Idx),1,dim));
        
        for d=1:dim
            X_DLH(t,d) = Positions(t,d) + rand*(Positions(randIdx(d),d) - Positions(r1(t),d));
        end
        
        X_DLH(t,:) = boundConstraint(X_DLH(t,:), Positions(t,:), lu);
        Fit_DLH(t) = fobj(X_DLH(t,:));
    end
    
    % ================= SELECTION =================
    mask = Fit_GWO < Fit_DLH;
    
    tmpFit = Fit_GWO;
    tmpFit(~mask) = Fit_DLH(~mask);
    
    tmpPositions = X_GWO;
    tmpPositions(~mask,:) = X_DLH(~mask,:);
    
    % ================= UPDATE PERSONAL BEST =================
    mask2 = pBestScore <= tmpFit;
    
    pBestScore(~mask2) = tmpFit(~mask2);
    pBest(~mask2,:) = tmpPositions(~mask2,:);
    
    % Update population
    Positions = tmpPositions;
    Fit = tmpFit;
    
    Convergence_curve(iter) = Alpha_score;
end

% ================= OUTPUT =================
gwoDatOutput.xmin = Alpha_pos;
gwoDatOutput.fmin = Alpha_score;
gwoDatOutput.trace = Convergence_curve;

end

% ============================================================
% ================== BOUND CONSTRAINT =========================
% ============================================================
function vi = boundConstraint(vi, pop, lu)

[NP, ~] = size(pop);

if size(vi,1)==1
    NP = 1;
end

xl = repmat(lu(1,:), NP, 1);
xu = repmat(lu(2,:), NP, 1);

pos = vi < xl;
vi(pos) = (pop(pos) + xl(pos))/2;

pos = vi > xu;
vi(pos) = (pop(pos) + xu(pos))/2;

end