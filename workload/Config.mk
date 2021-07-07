-include $(TMPDIR)/dotnet.config
$(TMPDIR)/dotnet.config: $(TOP)/build/Versions.props
	@mkdir -p $(TMPDIR)
	@grep "<MicrosoftDotnetSdkInternalPackageVersion>" build/Versions.props | sed -e 's/<\/*MicrosoftDotnetSdkInternalPackageVersion>//g' -e 's/[ \t]*/TARGET_DOTNET_VERSION=/' > $@

ifeq ($(DESTVER),)
TARGET_DOTNET_VERSION_BAND = $(firstword $(subst -, ,$(TARGET_DOTNET_VERSION)))
else
TARGET_DOTNET_VERSION = $(DESTVER)
TARGET_DOTNET_VERSION_BAND = $(firstword $(subst -, ,$(DESTVER)))
endif

ifeq ($(DESTDIR),)
TARGET_DOTNET_DIR = $(TOP)/tools/dotnet
else
TARGET_DOTNET_DIR = $(DESTDIR)
endif

TARGET_DOTNET_MANIFEST_BAND_DIR = $(TARGET_DOTNET_DIR)/sdk-manifests/$(TARGET_DOTNET_VERSION_BAND)

# DOTNET6
DOTNET6 = $(TARGET_DOTNET_DIR)/dotnet

$(TOP)/tools/dotnet-install.sh:
	@mkdir -p $(TOP)/tools
	@curl -o $@ \
		https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh

$(DOTNET6): $(TOP)/tools/dotnet-install.sh
	@bash $< -v $(TARGET_DOTNET_VERSION) -i $(TARGET_DOTNET_DIR)

# COMMIT DISTANCE and HASH
TIZEN_VERSION_BLAME_COMMIT := $(shell git blame $(TOP)/Versions.mk HEAD | grep TIZEN_PACK_VERSION | sed 's/ .*//')
TIZEN_COMMIT_DISTANCE := $(shell git log $(TIZEN_VERSION_BLAME_COMMIT)..HEAD --oneline | wc -l)

CURRENT_HASH := $(shell git log -1 --pretty=%h)

# BRANCH_NAME
ifeq ($(BRANCH_NAME),)
	CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
else
	CURRENT_BRANCH := $(BRANCH_NAME)
endif

# PRERELEASE_TAG, PULLREQUEST_ID
ifneq ($(PRERELEASE_TAG),)
PRERELEASE_VERSION := $(PRERELEASE_TAG)
else
ifneq ($(PULLREQUEST_ID),)
PRERELEASE_VERSION := ci.pr.gh$(PULLREQUEST_ID)
else
PRERELEASE_VERSION := ci.$(CURRENT_BRANCH)
endif
endif

TIZEN_PACK_VERSION_FULL := $(TIZEN_PACK_VERSION)-$(PRERELEASE_VERSION).$(TIZEN_COMMIT_DISTANCE)
