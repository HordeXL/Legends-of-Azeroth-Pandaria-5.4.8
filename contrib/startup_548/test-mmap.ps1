param([string]$BoostDirectory='C:/local/boost_1_85_0')
$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
$dir="$root/Build/startup-audit-20261005"
New-Item -ItemType Directory -Force $dir | Out-Null
Push-Location $root
try {
    if (!(Test-Path 'Build/bin/RelWithDebInfo/mmaps/0000_31_31.mmtile')) { throw 'Required test navigation tile is absent' }
    if (Test-Path 'Build/bin/RelWithDebInfo/mmaps/0000_63_63.mmtile') { throw 'Missing-tile test requires an absent 0000_63_63 tile' }
    $includes=@('/Isrc/common','/Isrc/common/Configuration','/Isrc/common/Collision/Management',
        '/Isrc/common/Utilities','/Idep/recastnavigation/Detour/Include','/Idep/fmt/include',"/I$BoostDirectory")
    $libs=@('Build/src/common/RelWithDebInfo/common.lib',
        'Build/dep/recastnavigation/Detour/RelWithDebInfo/Detour.lib',
        'Build/dep/fmt/RelWithDebInfo/fmt.lib','Build/dep/SFMT/RelWithDebInfo/sfmt.lib',
        'dbghelp.lib','ws2_32.lib','bcrypt.lib','user32.lib')
    & cl.exe /nologo /EHsc /std:c++20 /MD /DNDEBUG /DNO_CORE_FUNCS @includes "$PSScriptRoot/mmap_loading.cpp" "/Fo:$dir/mmap_loading.obj" "/Fe:$dir/mmap_loading.exe" /link @libs "/LIBPATH:$BoostDirectory/lib64-msvc-14.3"
    if($LASTEXITCODE){throw 'MMAP test compilation failed'}
    [IO.File]::WriteAllText("$dir/mmap-test.conf",'[worldserver]'+"`n"+'DataDir = "'+$root.Replace('\','/')+'/Build/bin/RelWithDebInfo"'+"`n")
    & "$dir/mmap_loading.exe" "$dir/mmap-test.conf"
    if($LASTEXITCODE){throw 'MMAP loading regression failed'}
} finally {Pop-Location}
