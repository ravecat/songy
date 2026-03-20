import redaxios from 'redaxios';

function headersToObject(headers) {
  if (!headers || typeof headers.forEach !== 'function') return headers;
  const obj = {};
  headers.forEach((value, key) => {
    obj[key] = value;
  });
  return obj;
}

function normalizeResponse(promise) {
  return promise.then(
    (res) => {
      if (res && res.headers && typeof res.headers.forEach === 'function') {
        res.headers = headersToObject(res.headers);
      }
      return res;
    },
    (err) => {
      if (err && err.headers && typeof err.headers.forEach === 'function') {
        err.headers = headersToObject(err.headers);
      }
      return Promise.reject(err);
    },
  );
}

function wrap(instance) {
  function axios(configOrUrl, config) {
    return normalizeResponse(instance(configOrUrl, config));
  }

  axios.defaults = instance.defaults;
  axios.request = (config) => normalizeResponse(instance.request(config));

  for (const method of ['get', 'delete', 'head', 'options']) {
    axios[method] = (url, config) =>
      normalizeResponse(instance[method](url, config));
  }

  for (const method of ['post', 'put', 'patch']) {
    axios[method] = (url, data, config) =>
      normalizeResponse(instance[method](url, data, config));
  }

  axios.all = Promise.all.bind(Promise);
  axios.spread = (fn) => fn.apply.bind(fn, fn);
  axios.isCancel = isCancel;
  axios.isAxiosError = isAxiosError;
  axios.CanceledError = CanceledError;
  axios.CancelToken = instance.CancelToken;

  axios.create = (defaults) => wrap(redaxios.create(defaults));

  return axios;
}

class CanceledError extends Error {
  constructor(message) {
    super(message || 'canceled');
    this.__CANCEL__ = true;
  }
}

function isCancel(value) {
  return !!(
    (value && value.__CANCEL__) ||
    (value instanceof DOMException && value.name === 'AbortError')
  );
}

function isAxiosError(value) {
  return !!(value && value.config);
}

function mergeConfig(config1, config2) {
  const merged = { ...config1 };
  if (!config2) return merged;
  for (const key of Object.keys(config2)) {
    const val = config2[key];
    if (val && typeof val === 'object' && !Array.isArray(val)) {
      merged[key] =
        merged[key] && typeof merged[key] === 'object'
          ? { ...merged[key], ...val }
          : val;
    } else if (val !== undefined) {
      merged[key] = val;
    }
  }
  return merged;
}

redaxios.defaults.xsrfCookieName = 'XSRF-TOKEN';
redaxios.defaults.xsrfHeaderName = 'X-XSRF-TOKEN';

const axios = wrap(redaxios);

export default axios;
export { isCancel, isAxiosError, mergeConfig, CanceledError };
