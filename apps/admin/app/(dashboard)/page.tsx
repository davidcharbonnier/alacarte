import { auth } from '@/auth';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Users } from 'lucide-react';
import { DashboardStats } from '@/components/dashboard/dashboard-stats';

export default async function DashboardPage() {
  const session = await auth();

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Dashboard</h1>
      
      <DashboardStats />

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Welcome to A la carte Admin Panel</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-gray-600">
            Manage your items, users, and ratings from this admin interface.
            Use the sidebar navigation to access different sections.
          </p>
          {session?.user && (
            <p className="text-sm text-gray-500 mt-2">
              Logged in as: {session.user.email}
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
