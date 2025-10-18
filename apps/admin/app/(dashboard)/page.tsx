import { auth } from '@/auth';
import { DashboardStats } from '@/components/dashboard/dashboard-stats';

export default async function DashboardPage() {
  const session = await auth();

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold mb-2">Dashboard</h1>
        <p className="text-muted-foreground">
          Welcome back{session?.user?.name ? `, ${session.user.name}` : ''}! Manage your items and users.
        </p>
      </div>
      
      {/* Stats Cards */}
      <DashboardStats />
    </div>
  );
}
