#!/usr/bin/env bash

codecov --token=${CODECOV_TOKEN}

NEPHOS_VERSION=$(cat setup.py | grep 'VERSION =' | awk '{print $3}')
echo "Nephos version is $NEPHOS_VERSION"

PACKAGE_PYPI=$(curl -s https://pypi.org/pypi/nephos/json | jq '.releases | keys[]' | grep ${NEPHOS_VERSION})
echo "On PyPI we have $PACKAGE_PYPI"

if [[ ${PACKAGE_PYPI} ]]
then
    echo "Package has already been uploaded to PyPI"
elif [[ "$TRAVIS_PULL_REQUEST" == "true" ]]
then
    echo "TRAVIS_PULL_REQUEST is 'true'"
elif [[ ${TWINE_USERNAME} && ${TWINE_PASSWORD} ]]
then
    python setup.py upload
else
    echo "TWINE_USERNAME and/or TWINE_PASSWORD not available"
fi

if [[ "$TRAVIS_PULL_REQUEST" == "true" ]]
then
    # Cosmic Ray (Mutation testing)
    pip install cosmic_ray
    cosmic-ray -v INFO init cosmic_ray_config.yaml my_session.sqlite
    cosmic-ray -v INFO exec my_session.sqlite
    cr-report my_session.sqlite | grep 'complete:'
    cr-report my_session.sqlite | grep 'survival rate:'
fi
