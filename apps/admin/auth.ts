import NextAuth from "next-auth"
import Google from "next-auth/providers/google"
import axios from "axios"

const API_URL = process.env.API_URL || "http://localhost:8080"

/**
 * Transform backend GORM format to frontend JavaScript conventions for User
 */
function transformUser(backendUser: any) {
  return {
    id: backendUser.ID,
    email: backendUser.email,
    display_name: backendUser.display_name,
    full_name: backendUser.full_name,
    avatar: backendUser.avatar,
    google_id: backendUser.google_id,
    discoverable: backendUser.discoverable,
    is_admin: backendUser.is_admin,
    created_at: backendUser.CreatedAt,
    updated_at: backendUser.UpdatedAt,
    last_login_at: backendUser.last_login_at,
  };
}

export const { handlers, signIn, signOut, auth } = NextAuth({
  trustHost: true, // Trust the host from the request (required for Cloud Run)
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          prompt: "consent",
          access_type: "offline",
          response_type: "code"
        }
      }
    }),
  ],
  callbacks: {
    async jwt({ token, account, profile }) {
      // On first sign in, exchange Google token for backend JWT
      if (account?.id_token) {
        try {
          // Step 1: Exchange Google token for backend JWT
          const authResponse = await axios.post(`${API_URL}/auth/google`, {
            id_token: account.id_token,
            access_token: account.access_token,
          });

          const backendToken = authResponse.data.token;

          // Step 2: Check if user has admin privileges
          const adminCheckResponse = await axios.get(`${API_URL}/api/auth/check-admin`, {
            headers: {
              Authorization: `Bearer ${backendToken}`,
            },
          });

          // Reject authentication if user is not admin
          if (!adminCheckResponse.data.is_admin) {
            console.error("Admin access required - user is not an administrator");
            throw new Error("AccessDenied"); // NextAuth will catch this and redirect with error param
          }

          // Store backend JWT and transformed user in session
          token.backendToken = backendToken;
          token.backendUser = transformUser(authResponse.data.user);
        } catch (error) {
          console.error("Authentication failed:", error);
          
          // Distinguish between different error types
          if (axios.isAxiosError(error)) {
            if (!error.response) {
              // Network error - backend unreachable
              throw new Error("ServiceUnavailable");
            } else if (error.response.status === 401 || error.response.status === 403) {
              // Auth error from backend
              throw new Error("AccessDenied");
            }
          }
          
          // Generic auth failure
          throw new Error("AuthenticationFailed");
        }
      }
      
      return token;
    },
    async session({ session, token }) {
      // Pass backend JWT to session
      session.backendToken = token.backendToken as string;
      session.user = token.backendUser as any;
      return session;
    },
  },
  pages: {
    signIn: '/login',
    error: '/login',
  },
  session: {
    strategy: "jwt",
    maxAge: 60 * 60 * 24, // 24 hours (match backend)
  },
})
