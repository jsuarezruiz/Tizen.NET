.DEFAULT_GOAL := packs

# FIXME: only for test
PRERELEASE_TAG=preview.6

TOP := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

BINDIR := $(TOP)/bin
TMPDIR := $(TOP)/.tmp
NUPKG_BIN_DIR := $(BINDIR)/nuget-unsigned
MSI_BIN_DIR := $(BINDIR)/windows

include $(TOP)/Versions.mk
include $(TOP)/Config.mk


# Create nuget packages for manifest and packs
define CreateNuGetPkgs
$(NUPKG_BIN_DIR)/$(1)$(3).$(2).nupkg: $(DOTNET6)
		@$(DOTNET6) pack --nologo $(TOP)/build/$(1).proj \
			-p:Configuration=Release \
			-p:IncludeSymbols=False \
			-p:TizenPackVersion=$(2) \
			-p:TizenVersionHash=$(CURRENT_HASH) \
			-p:DotNetPreviewVersionBand=$(4)

NUPKG_TARGETS += $(NUPKG_BIN_DIR)/$(1)$(3).$(2).nupkg
endef

$(eval $(call CreateNuGetPkgs,Samsung.NET.Sdk.Tizen,$(TIZEN_PACK_VERSION_FULL),.Manifest-$(TARGET_DOTNET_VERSION_BAND),$(TARGET_DOTNET_VERSION_BAND)))
$(eval $(call CreateNuGetPkgs,Samsung.Tizen.Sdk,$(TIZEN_PACK_VERSION_FULL)))
$(eval $(call CreateNuGetPkgs,Samsung.Tizen.Ref,$(TIZEN_PACK_VERSION_FULL)))
$(eval $(call CreateNuGetPkgs,Samsung.Tizen.Templates,$(TIZEN_PACK_VERSION_FULL)))

.PHONY: packs
packs: $(NUPKG_TARGETS)

define TEMP_NUGET_CONFIG_BODY
<?xml version="1.0" encoding="utf-8"?>
<configuration>
<packageSources>
	<clear />
	<add key="local" value="$(NUPKG_BIN_DIR)" />
</packageSources>
</configuration>
endef
export TEMP_NUGET_CONFIG_BODY

$(TMPDIR)/NuGet.config:
	@mkdir -p $(TMPDIR)
	@echo "$$TEMP_NUGET_CONFIG_BODY" > $@

TARGET_SDK_MANIFEST_DIR=$(TARGET_DOTNET_MANIFEST_BAND_DIR)/samsung.net.sdk.tizen
$(TARGET_SDK_MANIFEST_DIR):
	@mkdir -p $@
	@cp -f $(TOP)/LICENSE $@
	@cp -f $(NUPKG_BIN_DIR)/workload-manifest/WorkloadManifest.json $@
	@cp -f $(TOP)/src/Samsung.NET.Sdk.Tizen/WorkloadManifest.targets $@

# Install workload to the dotnet sdk
.PHONY: install
install: packs $(TMPDIR)/NuGet.config | $(TARGET_SDK_MANIFEST_DIR)
	@(cd $(TMPDIR); $(TARGET_DOTNET_DIR)/dotnet workload install tizen --skip-manifest-update)

# Uninstall workload from the dotnet sdk
.PHONY: uninstall
uninstall: $(DOTNET_EXEC)
	@rm -fr $(TARGET_SDK_MANIFEST_DIR)
	@rm -fr $(TARGET_DOTNET_DIR)/packs/Samsung.Tizen.Sdk
	@rm -fr $(TARGET_DOTNET_DIR)/packs/Samsung.Tizen.Ref
	@rm -f $(TARGET_DOTNET_DIR)/template-packs/samsung.tizen.templates.*.nupkg

# Create MSI windows bundle
define CreateMsi
$(MSI_BIN_DIR)/Samsung.NET.Workload.Tizen.$(1).wix: $(TMPDIR)/msi
	@$(DOTNET6) msbuild --nologo $(TOP)/build/GenerateWixFile.proj \
									-t:Generate \
									-p:MSIVersion=$(TIZEN_PACK_VERSION_FULL) \
									-p:SourceDirectory=$(TMPDIR)/msi \
									-p:DestinationFile="$$@"

$(MSI_BIN_DIR)/Samsung.NET.Workload.Tizen.$(1).msi: $(MSI_BIN_DIR)/Samsung.NET.Workload.Tizen.$(1).wix
	@wixl -o "$$@" "$$<" -a x64

MSI_TARGET := $(MSI_BIN_DIR)/Samsung.NET.Workload.Tizen.$(1).msi
endef

prepare-create-installer: packs
	@rm -fr $(TMPDIR)/msi
	$(call InstallWorkload,$(abspath $(TMPDIR)/msi),$(DESTVER))

$(eval $(call CreateMsi,$(TIZEN_PACK_VERSION_FULL)))

$(TMPDIR)/msi: install
	@mkdir -p $@/sdk-manifests/$(TARGET_DOTNET_VERSION_BAND)
	@cp -fr $(TARGET_SDK_MANIFEST_DIR) $@/sdk-manifests/$(TARGET_DOTNET_VERSION_BAND)
	@mkdir -p $@/packs
	@cp -fr $(TARGET_DOTNET_DIR)/packs/Samsung.Tizen.Sdk $@/packs
	@cp -fr $(TARGET_DOTNET_DIR)/packs/Samsung.Tizen.Ref $@/packs
	@mkdir -p $@/template-packs
	@cp -f $(TARGET_DOTNET_DIR)/template-packs/samsung.tizen.templates.*.nupkg $@/template-packs

.PHONY: msi
msi: $(MSI_TARGET)

# Remove artifacts and temporary files
.PHONY: clean
clean:
	@rm -fr $(BINDIR)
	@rm -fr $(TMPDIR)
	@rm -fr $(TOP)/build/obj/
