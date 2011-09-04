
JC := javac

BUILD_DIR := build
SRC_DIR := src
TEST_DIR := test
LIB_DIR := lib

SRC_CP := $(BUILD_DIR)/classes
TEST_CP := $(BUILD_DIR)/test/classes
LIB_CP := $(shell find $(LIB_DIR) -name "*.jar" -printf "%p:")
CLASSPATH := $(SRC_CP):$(TEST_CP):$(LIB_CP):$(SRC_DIR)

SRC_FILES := $(shell find $(SRC_DIR) -name "*.java")
TEST_FILES := $(shell find $(TEST_DIR) -name "*.java")

SRC_OBJ := $(patsubst $(SRC_DIR)/%.java, $(SRC_CP)/%.class, $(SRC_FILES))
TEST_OBJ := $(patsubst $(TEST_DIR)/%.java, $(TEST_CP)/%.class, $(TEST_FILES))

.PHONY: dirs clean all build-src build-test
.SUFFIXES: .java .class

all: build-src build-test

build-src: dirs $(SRC_OBJ)

build-test: dirs build-src $(TEST_OBJ)

$(TEST_CP)/%.class: $(TEST_DIR)/%.java
	@$(JC) -cp $(CLASSPATH):$(TEST_DIR) $< -d $(TEST_CP)

$(SRC_CP)/%.class: $(SRC_DIR)/%.java
	@$(JC) -cp $(CLASSPATH):$(TEST_SRC) $< -d $(SRC_CP)

clean:
	@$(RM) -r $(BUILD_DIR)

dirs:
	@mkdir -p $(SRC_CP) $(TEST_CP)
	@mkdir -p $(patsubst $(SRC_DIR)/%, $(SRC_CP)/%, \
		$(shell find $(SRC_DIR) -type d))
	@mkdir -p $(patsubst $(TEST_DIR)/%, $(TEST_CP)/%, \
		$(shell find $(TEST_DIR) -type d))

