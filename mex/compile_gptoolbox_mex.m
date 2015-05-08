warning([ ...
  'This is **VERY** experimental. In principle, this should compile all ', ...
  'of the mex functions in this directory. In practice, users will ', ...
  'surely have to adjust paths and flags at the top of this file.']);
input('Hit any key to continue...');

MEXOPTS={'-v','-largeArrayDims','-DMEX'};
MSSE42='CXXFLAGS=$CXXFLAGS -msse4.2';
STDCPP11='CXXFLAGS=$CXXFLAGS -std=c++11';
if exist('/usr/local/include/eigen3')
  EIGEN_INC='-I/usr/local/include/eigen3';
elseif exist('/opt/local/include/eigen3')
  EIGEN_INC='-I/opt/local/include/eigen3';
end
CLANG={'CXX=/usr/bin/clang++','LD=/usr/bin/clang++'};
FRAMEWORK_LDFLAGS='LDFLAGS=\$LDFLAGS -framework Foundation -framework AppKit';
NOOPT_LDOPTIMFLAGS='LDOPTIMFLAGS="-O "';

% See libigl documentation. In short, Libigl is a header-only library by
% default: no compilation needed (like Eigen). There's an advanced **option**
% to precompile libigl as a static library. This cuts down on compilation time.
% It is optional and more difficult to set up. Set this to true only if you
% know what you're doing.
use_libigl_static_library = false;
LIBIGL_INC=sprintf('-I%s/include',path_to_libigl);
if use_libigl_static_library
  LIBIGL_FLAGS='-DIGL_STATIC_LIBRARY';
  LIBIGL_LIB=sprintf('-L%s/lib -ligl',path_to_libigl);
  LIBIGL_LIBEMBREE='-liglembree';
  LIBIGL_LIBMATLAB='-liglmatlab';
  LIBIGL_LIBCGAL='-liglcgal';
  LIBIGL_LIBBOOLEAN='-liglboolean';
  LIBIGL_LIBSVD3X3='-liglsvd3x3';
else
  % `mex` has a silly requirement that arguments be non-empty, hence the NOOP
  % defines
  LIBIGL_FLAGS='-DIGL_SKIP';
  LIBIGL_LIB='-DIGL_SKIP';
  LIBIGL_LIBMATLAB='-DIGL_SKIP';
  LIBIGL_LIBEMBREE='-DIGL_SKIP';
  LIBIGL_LIBCGAL='-DIGL_SKIP';
  LIBIGL_LIBBOOLEAN='-DIGL_SKIP';
  LIBIGL_LIBSVD3X3='-DIGL_SKIP';
end
LIBIGL_BASE={LIBIGL_INC,LIBIGL_FLAGS,LIBIGL_LIB,LIBIGL_LIBMATLAB};

SVD_INC=sprintf('-I%s/external/Singular_Value_Decomposition/',path_to_libigl);

EMBREE=[path_to_libigl '/external/embree'];
EMBREE_INC=strsplit(sprintf('-I%s -I%s/include/',EMBREE,EMBREE));
EMBREE_LIB=strsplit(sprintf('-L%s/build -lembree -lsys',EMBREE));

CORK=[path_to_libigl '/external/cork'];
CORK_INC=sprintf('-I%s/include',CORK);
CORK_LIB=strsplit(sprintf('-L%s/lib -lcork',CORK));

if exist('/usr/local/include/CGAL')
  CGAL='/usr/local/';
elseif exist('/opt/local/include/CGAL')
  CGAL='/opt/local/';
end
CGAL_INC=sprintf('-I%s/include',CGAL);
CGAL_LIB=strsplit(sprintf('-L%s/lib -lCGAL -lCGAL_Core -lgmp -lmpfr',CGAL));
CGAL_FLAGS='CXXFLAGS=\$CXXFLAGS -frounding-math';

BOOST='/opt/local/';
BOOST_INC=sprintf('-I%s/include',BOOST);
BOOST_LIB=strsplit(sprintf('-L%s/lib -lboost_thread-mt -lboost_system-mt',BOOST));


mex( ...
  MEXOPTS{:},...
  MSSE42, ...
  STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  EMBREE_INC{:}, EMBREE_LIB{:}, LIBIGL_LIBEMBREE, ...
  'ambient_occlusion.cpp');

mex(MEXOPTS{:},'-output','bone_visible_mex','bone_visible.cpp');

mex( ...
  MEXOPTS{:},...
  MSSE42, ...
  STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  EMBREE_INC{:}, EMBREE_LIB{:}, LIBIGL_LIBEMBREE, ...
  'bone_visible_embree.cpp');

mex( ...
  MEXOPTS{:}, ...
  STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  'collapse_small_triangles.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, ...
  STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBCGAL, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'decimate_cgal.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBSVD3X3, ...
  SVD_INC, ...
  'fit_rotations_mex.cpp');

% impaste is currently only implemented for mac
if ismac
  mex( ...
    MEXOPTS{:}, MSSE42, STDCPP11, ...
    CLANG{:},NOOPT_LDOPTIMFLAGS,FRAMEWORK_LDFLAGS, ...
    '-output','impaste','impaste.cpp','paste.mm');
end

mex( ...
  MEXOPTS{:}, ...
  STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  'in_element_aabb.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBCGAL, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'intersect_other.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  LIBIGL_LIBCGAL, LIBIGL_LIBBOOLEAN, ...
  CORK_INC,CORK_LIB{:}, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'mesh_boolean.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  'outer_hull.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBCGAL, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'point_mesh_squared_distance.cpp');

mex( ...
  MEXOPTS{:}, ...
  STDCPP11, ...
  'ray_mesh_intersect.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBCGAL, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'selfintersect.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBCGAL, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'signed_distance.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  LIBIGL_LIBCGAL, ...
  CGAL_INC,CGAL_LIB{:},CGAL_FLAGS, ...
  BOOST_INC,BOOST_LIB{:}, ...
  'signed_distance_isosurface.cpp');

mex( ...
  MEXOPTS{:}, ...
  STDCPP11, ...
  'solid_angle.cpp');

mex( ...
  MEXOPTS{:}, MSSE42, STDCPP11, ...
  LIBIGL_BASE{:},EIGEN_INC, ...
  '-Iwinding_number', ...
  '-output','winding_number', ...
  'winding_number.cpp','winding_number/parse_rhs.cpp','winding_number/prepare_lhs.cpp');
