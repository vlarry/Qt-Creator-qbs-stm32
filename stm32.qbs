import qbs
import qbs.FileInfo

Product
{
    type: ["application", "hex", "bin", "size", "flash"]
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
            filePath: project.path + "/debug/bin/" + input.baseName + ".hex"
            fileTags: ["hex"]
        }

        prepare:
        {
            var args = ["-O", "ihex"];

            args.push(input.filePath);
            args.push(output.filePath);

            var objcopyPath = "c:/development/gcc-arm/bin/arm-none-eabi-objcopy.exe";

            var cmd = new Command(objcopyPath, args);

            cmd.description = "convert to hex...";
            cmd.highlight = "linker"
            cmd.silent = false;

            return cmd;
        }
    }

    Rule
    {
        inputs: ["application"]

        Artifact
        {
            filePath: project.path + "/debug/bin/" + input.baseName + ".bin"
            fileTags: ["bin"]
        }

        prepare:
        {
            var args = ["-O", "binary"];

            args.push(input.filePath);
            args.push(output.filePath);

            var objcopyPath = "c:/development/gcc-arm/bin/arm-none-eabi-objcopy.exe";

            var cmd = new Command(objcopyPath, args);

            cmd.description = "convert to bin...";
            cmd.highlight = "linker"
            cmd.silent = false;

//            var flashOpenOCD = "c:/development/openocd_0_10_0/bin/openocd.exe";
//            var flashCfgStlink = "c:/development/openocd_0_10_0/scripts/interface/stlink-v2.cfg";
//            var flashCfgStm32 = "c:/development/openocd_0_10_0/scripts/target/stm32f1x.cfg";
//            var fileFlashing = "flash write_image erase " + input.filePath;
//            var argsFlashing =
//            [
//                "-f", flashCfgStlink,
//                "-f", flashCfgStm32,
//                "-c", "init",
//                "-c", "halt",
//                "-c", fileFlashing,
//                "-c", "reset",
//                "-c", "shutdown"
//            ]

//            var cmd_flash = new Command(flashOpenOCD, argsFlashing);

//            cmd_flash.description = "flashing to uC: " + FileInfo.fileName(input.filePath);
//            cmd_flash.highlight = "linker";

            return [cmd/*, cmd_flash*/];
        }
    }

    Rule
    {
        inputs: "application"

        Artifact
        {
            fileTags: "size"
        }

        prepare:
        {
            var args = [input.filePath];
            var sizePath = "c:/development/gcc-arm/bin/arm-none-eabi-size.exe";

            var cmd = new Command(sizePath, args);

            cmd.description = "Size of sections:";
            cmd.highlight = "linker"
            cmd.silent = false;

            return cmd;
        }
    }
}
