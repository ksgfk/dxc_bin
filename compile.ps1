param($dxc)
Write-Host "DXC source path: $dxc"
if ($IsLinux) {
    Write-Host "build linux"
} elseif ($IsMacOS) {
    Write-Host "build macos"
} elseif ($IsWindows) {
    Write-Host "build windows"
} else {
    throw "unknwon OS" + [System.Environment]::OSVersion.Platform
}

$build_dir = "dxc_build"
New-Item -Path $build_dir -ItemType Directory

$cmake_conf = New-Object System.Collections.ArrayList
$cmake_conf.AddRange(@("-S", $dxc))
$cmake_conf.AddRange(@("-B", $build_dir))
$cmake_conf.AddRange(@("-C", "$dxc/cmake/caches/PredefinedParams.cmake"))
$cmake_conf.Add("-DCMAKE_BUILD_TYPE=Release")
if ($IsWindows) {
    $cmake_conf.AddRange(@("-T", "ClangCL"))
}
$config_pros = Start-Process -FilePath "cmake" -ArgumentList $cmake_conf -Wait -NoNewWindow -PassThru
if ($config_pros.ExitCode -ne 0) {
    throw "cannot config"
}

$cmake_bu = @("--build", $build_dir, "--config", "Release")
$compile_proc = Start-Process -FilePath "cmake" -ArgumentList $cmake_bu -Wait -NoNewWindow -PassThru
if ($compile_proc.ExitCode -ne 0) {
    throw "cannot config"
}

$bin_dir = "dxc_binary"
New-Item -Path $bin_dir -ItemType Directory
New-Item -Path "$bin_dir/bin" -ItemType Directory
New-Item -Path "$bin_dir/include" -ItemType Directory
Copy-Item "$dxc/include/dxc/dxcapi.h" -Destination "$bin_dir/include"
Copy-Item "$dxc/include/dxc/dxcerrors.h" -Destination "$bin_dir/include"
Copy-Item "$dxc/include/dxc/dxcisense.h" -Destination "$bin_dir/include"
if ($IsLinux) {
    Copy-Item "$build_dir/bin/dxc" -Destination "$bin_dir/bin"
    Copy-Item "$build_dir/lib/libdxcompiler.so" -Destination "$bin_dir/bin"
} elseif ($IsMacOS) {
    Copy-Item "$build_dir/bin/dxc" -Destination "$bin_dir/bin"
    Copy-Item "$build_dir/lib/libdxcompiler.dylib" -Destination "$bin_dir/bin"
} elseif ($IsWindows) {
    Copy-Item "$build_dir/bin/dxc.exe" -Destination "$bin_dir/bin"
    Copy-Item "$build_dir/bin/dxc.pdb" -Destination "$bin_dir/bin"
    Copy-Item "$build_dir/bin/dxcompiler.dll" -Destination "$bin_dir/bin"
    Copy-Item "$build_dir/bin/dxcompiler.pdb" -Destination "$bin_dir/bin"
}

$zip_name = ""
if ($IsLinux) {
    $zip_name = "dxc-linux-"
} elseif ($IsMacOS) {
    $zip_name = "dxc-macosx-"
} elseif ($IsWindows) {
    $zip_name = "dxc-win-"
}
$zip_name += [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$zip_name += ".zip"
Compress-Archive -Path "$bin_dir/*" -DestinationPath $zip_name.ToLower()
