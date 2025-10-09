import { DefaultSession } from "next-auth"

declare module "next-auth" {
  interface Session {
    backendToken?: string
    user: {
      id: number
      email: string
      display_name: string
      full_name: string
      is_admin: boolean
    } & DefaultSession["user"]
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    backendToken?: string
    backendUser?: any
  }
}
