# Project Operations

## Existing Web

- Install: `npm install`
- Build: `npm run build`

## UniApp

- Install: `cd uniapp && npm install`
- H5 dev: `npm run dev:h5`
- H5 build: `npm run build:h5`
- WeChat build: `npm run build:mp-weixin`
- App resources: `npm run build:app`
- Type check: `npm run type-check`

## Backpressure

- Keep UniApp work inside `uniapp/`; existing Web/backend changes may be user-owned.
- Type check and all three builds must pass before completion.
- Production App packaging still requires DCloud AppID and signing credentials.
- Production WeChat upload requires a mini-program AppID and platform domain allowlist.
