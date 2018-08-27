#!/usr/bin/env sh
$(which python) ./prechk.py
$(which python) ./genl10n.py ./pap/ ./pap/Resources/Localizations/Base.lproj/Localizable.strings -k .localized
$(which python) ./rm0objfiles.py
