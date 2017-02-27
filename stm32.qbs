import qbs
import qbs.FileInfo

Product
{
    type: ["application", "flash"]
    Depends { name: "cpp" }

    cpp.defines: ["STM32F10X_LD_VL"]
    cpp.positionIndependentCode: false
    cpp.enableExceptions: false
    cpp.executableSuffix: ".elf"
    cpp.driverFlags:
    [
        "-mthumb",
        "-mcpu=cortex-m3",
        "-mfloat-abi=soft",
        "-fno-strict-aliasing",
        "-g3",
        "-Wall",
        "-mfpu=vfp",
        "-O0",
        "-flto",
    ]

    cpp.commonCompilerFlags:
    [
        "-fdata-sections",
        "-ffunction-sections",
        "-fno-inline",
        "-std=c++11",
        "-flto"
    ]

    cpp.linkerFlags:
    [
        "--specs=nano.specs",
        "-Wl,--start-group",
        "-Wl,--gc-sections",
        "-T" + path + "/src/system/linker/stm32f10x_flash.ld",
        "-lnosys",
        "-lgcc",
        "-lc",
        "-lstdc++",
        "-lm"
    ]

    cpp.includePaths:
    [
        "src/system/cmsis",
        "src/system/cmsis_boot",
        "src/system/cmsis_boot/statup"
    ]

    files:
    [
        "src/system/cmsis/*.h",
        "src/system/cmsis/*.h",
        "src/system/cmsis_boot/*.h",
        "src/system/cmsis_boot/*.c",
        "src/system/cmsis_boot/startup/*.c",
        "src/main.cpp"
    ]

    Properties
    {
        condition: qbs.buildVariant === "debug"
        cpp.defines: outer.concat(["DEBUG=1"])
        cpp.debugInformation: true
        cpp.optimization: "none"
    }

    Properties
    {
        condition: qbs.buildVariant === "release"
        cpp.debugInformation: false
        cpp.optimization: "small"
    }

    Rule
    {
        inputs: ["application"]

        Artifact
        {
            filePath: project.path + "/debug/bin/" + input.baseName + ".bin"
            fileTags: "flash"
        }

        prepare:
        {
            var sizePath = "c:/development/gcc-arm/bin/arm-none-eabi-size.exe";
            var objcopyPath = "c:/development/gcc-arm/bin/arm-none-eabi-objcopy.exe";
            var configStlinkPath = "c:/development/openocd_0_10_0/scripts/interface/stlink-v2.cfg";
            var configStm32Path = "c:/development/openocd_0_10_0/scripts/target/stm32f1x.cfg";
            var openocdPath = "c:/development/openocd_0_10_0/bin/openocd.exe";

            var argsSize = [input.filePath];
            var argsObjcopy = ["-O", "binary", input.filePath, output.filePath];

            var argsFlashing =
            [
                "-f", configStlinkPath,
                "-f", configStm32Path,
                "-c", "init",
                "-c", "halt",
                "-c", CMD,
                "-c", "reset",
                "-c", "shutdown"
            ];

            var cmdSize = new Command(sizePath, argsSize);
            var cmdObjcopy = new Command(objcopyPath, argsObjcopy);

            cmdSize.description = "Size of sections:";
            cmdSize.highlight = "linker";

            cmdObjcopy.description = "convert to bin...";
            cmdObjcopy.highlight = "linker";

            return [cmdSize, cmdObjcopy];
        }
    }
}
