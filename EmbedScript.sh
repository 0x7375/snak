# Do not try to embed if the Watch directory is not here, like in the Snak scheme
# While in SnackWithWatch it will be included

WATCH_APP=$(find "${BUILD_DIR}" -maxdepth 2 -name "SnakWatch.app" \
    ! -path "*/${WRAPPER_NAME}/Watch/*" 2>/dev/null | head -1)

if [ -n "${WATCH_APP}" ] && [ -d "${WATCH_APP}" ]; then
    mkdir -p "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Watch"
    cp -R "${WATCH_APP}" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Watch/"
fi
