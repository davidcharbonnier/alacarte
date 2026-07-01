## ADDED Requirements

### Requirement: Google OAuth sign-in via SPA

The admin panel SHALL authenticate users through Google OAuth directly from the browser, without a server-side proxy.

#### Scenario: User initiates sign-in

- **WHEN** an unauthenticated user navigates to the admin panel
- **THEN** the system SHALL display a "Sign in with Google" button using `@react-oauth/google`

#### Scenario: Google returns credential

- **WHEN** the user completes Google OAuth consent
- **AND** Google returns an `id_token` and `access_token`
- **THEN** the system SHALL POST both tokens to `POST /auth/google` on the Go backend

#### Scenario: Backend returns JWT

- **WHEN** the backend validates the Google tokens and returns `{ token, user, message }`
- **THEN** the system SHALL store the JWT in `sessionStorage` under the key `jwt_token`
- **AND** the system SHALL store the user object in application state (React Context)

#### Scenario: Google OAuth fails

- **WHEN** Google OAuth returns an error (user cancels, network failure, or invalid client)
- **THEN** the system SHALL display an error message on the login page
- **AND** the system SHALL allow the user to retry

#### Scenario: Backend rejects Google tokens

- **WHEN** the backend returns a 4xx error from `POST /auth/google`
- **THEN** the system SHALL display the backend error message on the login page
- **AND** the system SHALL NOT store any authentication state

### Requirement: Admin status verification

The admin panel SHALL verify that the authenticated user has admin privileges before granting access to the dashboard.

#### Scenario: User is admin

- **WHEN** a user completes Google OAuth and receives a backend JWT
- **AND** the system calls `GET /api/auth/check-admin` with the JWT
- **AND** the backend returns `{ is_admin: true }`
- **THEN** the system SHALL redirect the user to the dashboard

#### Scenario: User is not admin

- **WHEN** a user completes Google OAuth and receives a backend JWT
- **AND** the system calls `GET /api/auth/check-admin` with the JWT
- **AND** the backend returns `{ is_admin: false }`
- **THEN** the system SHALL display an access-denied page explaining the user is not an administrator
- **AND** the system SHALL offer a sign-out option

#### Scenario: Admin check fails

- **WHEN** the `GET /api/auth/check-admin` call fails (network error or server error)
- **THEN** the system SHALL display an error message
- **AND** the system SHALL offer a retry option

### Requirement: JWT attachment to API requests

The admin panel SHALL automatically attach the stored JWT to all API requests.

#### Scenario: Authenticated request

- **WHEN** a JWT exists in `sessionStorage`
- **AND** the Axios client makes any request to the Go backend
- **THEN** the request SHALL include an `Authorization: Bearer <jwt>` header

#### Scenario: No JWT available

- **WHEN** no JWT exists in `sessionStorage`
- **AND** the Axios client makes a request to the Go backend
- **THEN** the request SHALL NOT include an `Authorization` header

### Requirement: Token expiry handling

The admin panel SHALL handle expired JWT tokens gracefully.

#### Scenario: API returns 401

- **WHEN** any API request receives a 401 Unauthorized response
- **THEN** the system SHALL clear the JWT from `sessionStorage`
- **AND** the system SHALL clear the user from application state
- **AND** the system SHALL redirect the user to the login page

#### Scenario: Token expires during active session

- **WHEN** a user is on any admin page
- **AND** an API call returns 401 due to token expiry
- **THEN** the system SHALL redirect to the login page without displaying sensitive admin data

### Requirement: Session persistence across page refreshes

The admin panel SHALL maintain the authenticated session when the user refreshes the page.

#### Scenario: Page refresh with valid JWT

- **WHEN** the user refreshes the browser on any admin page
- **AND** a JWT exists in `sessionStorage`
- **THEN** the system SHALL read the JWT from `sessionStorage` on app initialization
- **AND** the system SHALL decode the JWT to rehydrate the user object into application state
- **AND** the Axios interceptor SHALL attach the JWT to subsequent requests
- **AND** the user SHALL remain on the current page without re-authentication

#### Scenario: Page refresh without JWT

- **WHEN** the user refreshes the browser
- **AND** no JWT exists in `sessionStorage`
- **THEN** the system SHALL redirect to the login page

### Requirement: Route protection

The admin panel SHALL prevent unauthenticated users from accessing admin pages.

#### Scenario: Unauthenticated user accesses protected route

- **WHEN** a user without a valid JWT navigates to any page except `/login` or `/access-denied`
- **THEN** the system SHALL redirect them to `/login`

#### Scenario: Authenticated user accesses login page

- **WHEN** a user with a valid JWT navigates to `/login`
- **THEN** the system SHALL redirect them to the dashboard

### Requirement: Sign-out

The admin panel SHALL allow users to sign out.

#### Scenario: User signs out

- **WHEN** a user clicks the sign-out button in the header
- **THEN** the system SHALL remove the JWT from `sessionStorage`
- **AND** the system SHALL clear the user from application state
- **AND** the system SHALL redirect to the login page