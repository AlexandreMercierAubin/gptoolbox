function D = is_delaunay(V,F,varargin)
  % IS_DELAUNAY Determine if each edge in F is intrinsically Delaunay.
  %
  % Inputs:
  %   V  #V by dim list of vertex positions
  %   F  #F by 3 list of triangles indices
  %   Optional:
  %     'SideLengths' followed by:
  %       l  #F by 3 list of side lengths corresponding to edges 23 31 12
  % Outputs:
  %   D  #F by 3 list of bools revealing whether edges corresponding 23 31 12
  %     are locally delaunay. Boundary edges are by definition Delaunay.
  %
  % Known bugs: does not make sense for non-manifold edges
  %

  % default values
  l = [];
  % Map of parameter names to variable names
  params_to_variables = containers.Map( ...
    {'SideLengths'}, {'l'});
  v = 1;
  while v <= numel(varargin)
    param_name = varargin{v};
    if isKey(params_to_variables,param_name)
      assert(v+1<=numel(varargin));
      v = v+1;
      % Trick: use feval on anonymous function to use assignin to this workspace
      feval(@()assignin('caller',params_to_variables(param_name),varargin{v}));
    else
      error('Unsupported parameter: %s',varargin{v});
    end
    v=v+1;
  end
  if isempty(l)
    l = edge_lengths(V,F);
  end
  nv = max(F(:));
  L = cotmatrix_intrinsic(l,F,nv);

  % [Fisher et al. 2007]
  allE = [F(:,[2 3]);F(:,[3 1]);F(:,[1 2])];
  D = full(reshape(L(sub2ind(size(L),allE(:,1),allE(:,2)))>0,size(F)));

  [~,B] = on_boundary(F);
  D(B) = true;

  %% Deal with non-manifold and boundary edges
  %sortE = sort(allE,2);
  %% Adjacency matrix for these "redirected" edges
  %DA = sparse(sortE(:,1),sortE(:,2),1,nv,nv);
  %% If edge occurs more than once it's non-manifold. Define that non-manifold
  %% edges *are* delaunay (like boundary)
  %D(DA>2) = true;
  %% If edge only occurs once then it's a boundary. Define that boundary edges
  %% *are* delaunay
  %D(DA==1) = true;

end
