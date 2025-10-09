import { auth } from "@/auth"
import { NextResponse } from "next/server"

export default auth((req) => {
  const isLoggedIn = !!req.auth
  const isOnLogin = req.nextUrl.pathname === '/login'

  // Allow access to login page
  if (isOnLogin) {
    if (isLoggedIn) {
      // Already logged in, redirect to dashboard
      return NextResponse.redirect(new URL('/', req.url))
    }
    return NextResponse.next()
  }

  // Protect all other routes
  if (!isLoggedIn) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  // Admin check is performed during login (in auth.ts jwt callback)
  // Middleware validates session existence, backend validates admin on each API call

  return NextResponse.next()
})

// Configure which routes to protect
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
