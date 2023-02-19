Read("orbits.g");

coxeterGraph := function(series, rank)
    local edges;
    edges := List([2..rank], j -> [j-1, j]);
    if series >= "D" then  edges[1][2] := 3;  fi;
    if series >= "E" then  edges[2][2] := 4;  fi;
    return edges;
end;

cartanMat := function(series, rank)
    local cartan,  ij,  i,  j;
    cartan := 2*IdentityMat(rank);;
    for ij in coxeterGraph(series, rank) do
        i := ij[1];  j := ij[2];
        cartan[i][j] := -1;
        cartan[j][i] := -1;
    od;
    if series = "B" then  cartan[1][2] := -2;  fi;
    if series = "C" then  cartan[2][1] := -2;  fi;
    if series = "F" then  cartan[3][4] := -2;  fi;  # sic!
    return cartan;
end;

absRoot := root -> SignInt(Sum(root)) * root;

onRoots := function(x, a)
    return absRoot(OnRight(x, a));
end;

orbits_with_words_and_edges := function(aaa, xxx, under)
    local   list,  edges,  words,  i,  k,  l,  z;
    words := List([1..Length(xxx)], i -> [i]);
    list := ShallowCopy(xxx);  edges := [];  i := 0;
    while i < Length(list) do
        i := i+1;
        for k in [1..Length(aaa)] do
            z := under(list[i], aaa[k]);
            l := Position(list, z);
            if l = fail then
                Add(list, z);
                Add(words, onWords(words[i], k));
                l := Length(list);
            fi;
            Add(edges, [i, l]);
        od;
    od;
    return rec(list := list, edges := edges, words := words);
end;

permutation := function(a, xxx, under)
    return Sortex(List(xxx, x-> under(x, a))) / Sortex(ShallowCopy(xxx));
end;

DeclareAttribute("Data", IsPermGroup);

coxeterGroup := function(C)
    local  one,  mats,  S,  s,  phi,  data,  G;
    one := C^0;  mats := [];  S := [1..Length(C)];
    for s in S do
        mats[s] := C^0;  mats[s]{S}[s] := one[s] - C[s];
    od;
    roots := orbits_with_words_and_edges(mats, C^0, onRoots);
    data := rec(mats := mats,  roots:= roots, rank := Length(S));
    data.N := Length(roots.list);
    data.phi := Concatenation(roots.list, -roots.list);
    data.perms := List(mats, m -> Permutation(m, data.phi, OnRight));
    G:= GroupWithGenerators(data.perms);
    SetData(G, data);
    return G;
end;

reflections := function(W)
    local reflection_from_word;
    reflection_from_word := function(w)
        return W.(w[1])^Product(Data(W).perms{w{[2..Length(w)]}});
    end;
    return List(Data(W).roots.words, reflection_from_word);
end;

coxeterlength:= function(W, w)
    return Number([1..Data(W).N], i-> i^w > Data(W).N);
end;

permCoxeterWord:= function(W, word)
    if word = [] then return (); fi;
    return Product(Data(W).perms{word});
end;

isLeftDescent:= function(W, w, s)
    return s^w > Data(W).N;
end;

coxeterWord:= function(W, w)
    local word, a;
    word:= [];
    while w <> () do
        a:= First([1..Data(W).rank], s-> isLeftDescent(W, w, s));
        Add(word, a); w:= Data(W).perms[a] * w;
    od;
    return word;
end;

reducedWord:= function(W, word)
    return coxeterWord(W, permCoxeterWord(W, word));
end;

longestElement:= function(W, J)
    local  wJ,  s;
    wJ:= ();
    while true do
        s:= First(J, s-> not isLeftDescent(W, wJ, s));
        if s = fail then  return wJ;  fi;
        wJ:= W.(s) * wJ;
    od;
end;

prefixes:= function(W, w)
    local onRightDescents;

    onRightDescents:= function(w, s)
        if isLeftDescent(W, w^-1, s) then
            return w * W.(s);
        else
            return w;
        fi;
    end;

    return orbit([1..Data(W).rank], w, onRightDescents);
end;

prefixes_with_edges:= function(W, w)
    local onRightDescents;

    onRightDescents:= function(w, s)
        if isLeftDescent(W, w^-1, s) then
            return w * W.(s);
        else
            return w;
        fi;
    end;

    return orbit_with_edges([1..Data(W).rank], w, onRightDescents);
end;

longestCosetElement:= function(W, J, L)
    return longestElement(W, J) * longestElement(W, L);
end;

tackOn := function(x, s)
    return Union(x, [s]);
end;

shape := function(W, J)
    local onParabolics;
    onParabolics := function(K, s)
        return OnSets(K, longestCosetElement(W, K, tackOn(K, s)));
    end;
    return orbit([1..Data(W).rank], J, onParabolics);
end;

takeAway:= function(x, s)
    return Difference(x, [s]);
end;

shapes := function(W)
    local onShapes, S;
    onShapes := function(x, s)
        return Set(shape(W, takeAway(x[1], s)));
    end;
    S := [1..Data(W).rank];
    return orbit(S, shape(W, S), onShapes);
end;

shape_with_edges := function(W, J)
    local onParabolics;
    onParabolics := function(K, s)
        return OnSets(K, longestCosetElement(W, K, tackOn(K, s)));
    end;
    return orbit_with_edges([1..Data(W).rank], J, onParabolics);
end;

parabolicComplement:= function(W, J)
    local   S,  list,  trans,  i,  gens,  K,  s,  a,  L,  j;
    S := [1..Data(W).rank];  list := [J];  trans := [()];
    gens := rec(ears := [], eyes := []);
    i := 0;
    while i < Length(list) do
        i := i+1;  K := list[i];
        for s in Difference(S, K) do
            a := longestCosetElement(W, K, tackOn(K, s));
            L := OnSets(K, a);  j := Position(list, L);
            if j = fail then
                Add(list, L);
                Add(trans, trans[i] * a);
            elif j = i then
                AddSet(gens.ears, trans[i] * a * trans[i]^-1);
            else
                AddSet(gens.eyes, trans[i] * a * trans[j]^-1);
            fi;
        od;
    od;
    return gens;
end;

byCyclicShift:= function(w, s)
    local y;
    y:= w^s;
    if coxeterlength(W, y) = coxeterlength(W, w) then
        return y;
    fi;
    return w;
end;

onInvolutions := function(x, s)
    if x * s = s * x then return OnRight(x, s); fi;
    return OnPoints(x, s);
end;

onInvolutionClasses:= function(x, a)
    local y;
    y:= Representative(x);
    if y^a <> y then return x; fi;
    return OnRight(y, a)^ActingDomain(x);
end;

involutionClasses := function(group)
    local gens;
    gens:= GeneratorsOfGroup(group);
    return orbit(orbits(gens, gens, OnPoints), Identity(group)^group, onInvolutionClasses);
end;

