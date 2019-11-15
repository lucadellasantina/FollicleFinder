for i = 1:numel(T.ImagesTODOFollicles)
    s = T.ImagesTODOFollicles{i};
    s = strrep(s, '.1' , '1');
    s = strrep(s, '.2' , '2');
    s = strrep(s, '.icloud' , '');
    T.ImagesTODOFollicles{i} = s;
end