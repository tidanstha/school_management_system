FROM debian:testing-slim
# MAINTAINER Andreas Kloeckner <inform@tiker.net>
EXPOSE 9941
ARG RLCONTAINER
RUN useradd runcode

RUN echo "---------------- BUILD VARIANT: $RLCONTAINER"

RUN echo 'APT::Default-Release "testing";' >> /etc/apt/apt.conf

RUN apt-get update
RUN apt-get -y -o APT::Install-Recommends=0 -o APT::Install-Suggests=0 install \
  python3-scipy \
  python3-numpy \
  python3-pip \
  python3-matplotlib \
  python3-pillow \
  graphviz \
  python3-pandas \
  python3-statsmodels \
  python3-skimage \
  python3-sympy \
  python3-pip \
  python3-dev \
  python3-setuptools \
  python3-cffi \
  g++

RUN if [ "$RLCONTAINER" = "full" ] ; then  apt-get -o APT::Install-Recommends=0 -o APT::Install-Suggests=0 -y install \
  "pocl-opencl-icd" \
  "libpocl2" \
  "libpocl2-common" \
  "ocl-icd-libopencl1" \
  "python3-pyopencl" \
  git; \
  fi

RUN if [ "$RLCONTAINER" = "full" ] ; then python3 -m pip install git+https://github.com/inducer/loopy.git; fi

RUN apt-get clean
RUN fc-cache

RUN mkdir -p /opt/runcode
ADD runcode /opt/runcode/
COPY code_feedback.py /opt/runcode/
COPY code_run_backend.py /opt/runcode/
RUN ls /opt/runcode

RUN sed -i s/TkAgg/Agg/ /etc/matplotlibrc
RUN echo "savefig.dpi : 80" >> /etc/matplotlibrc
RUN echo "savefig.bbox : tight" >> /etc/matplotlibrc

RUN if [ "$RLCONTAINER" = "full" ] ; then pip3 install --upgrade tensorflow; fi
RUN rm -Rf /root/.cache

# may use ./flatten-container.sh to reduce disk space

# Install Django and venv package
RUN apt-get update && apt-get install -y python3-django python3-venv

# Create a virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install additional Python packages in the virtual environment
RUN /opt/venv/bin/pip install gunicorn

# Set the working directory
WORKDIR /app

# Copy the project
COPY . /app/

# Expose the port the app runs on
EXPOSE 9941

# Run the application
CMD ["/opt/venv/bin/gunicorn", "--bind", "0.0.0.0:9941", "relate.wsgi:application"]